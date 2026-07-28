#pragma once

#include <algorithm>
#include <chrono>
#include <cstdint>
#include <ctime>
#include <exception>
#include <memory>
#include <mutex>
#include <stdexcept>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

#include <userver/formats/common/type.hpp>
#include <userver/formats/json/serialize.hpp>
#include <userver/formats/json/value.hpp>
#include <userver/formats/json/value_builder.hpp>
#include <userver/formats/parse/common_containers.hpp>
#include <userver/server/http/http_status.hpp>
#include <userver/utils/datetime_light.hpp>
#include <userver/utils/uuid7.hpp>

#include "datasource/http/userver.hpp"
#include "runtime/common.hpp"
#include <handlers/order_service_api/processorder/requests.hpp>
#include <handlers/order_service_api/processorder/responses.hpp>
#include <model/include/example/model/types/order_item.hpp>
#include <model/include/example/model/types/order_item_result.hpp>
#include <orderservice/internal/types/order.hpp>
#include <orderservice/internal/types/order_state.hpp>

namespace example::order_service::functions {

struct ProcessOrder final {
  using Request = handlers::order_service_api::processorder::Request;
  using Response = handlers::order_service_api::processorder::Response;

  struct SharedState final {
    std::mutex mutex;
    example::order_service::types::Order order;
    std::size_t expectedItems{};
    std::vector<example::model::types::OrderItemResult> results;
    bool responseSent{};
  };

  struct State final {
    std::shared_ptr<SharedState> shared;
  };

  explicit ProcessOrder(
      std::chrono::steady_clock::duration timeout = std::chrono::seconds{5})
      : timeout_(timeout) {}

  servicelib::BeginResult<State> beginRequest(
      servicelib::MessageContext context, auto&,
      servicelib::datasource::http::HandlerData& data) const {
    try {
      auto shared = std::make_shared<SharedState>();
      const auto json =
          userver::formats::json::FromString(data.request.RequestBody());
      const auto itemsJson = json["items"];
      if (itemsJson.IsMissing() || !itemsJson.IsArray() ||
          itemsJson.GetSize() == 0) {
        throw std::invalid_argument("items must not be empty");
      }

      auto orderId = data.request.GetHeader("X-Request-ID");
      if (orderId.empty()) {
        orderId = userver::utils::generators::GenerateUuidV7();
      }

      shared->order.id = std::move(orderId);
      shared->order.customer_id =
          stringField(json, "customer_id", "customerId", "");
      shared->order.trace_id = data.request.GetHeader("X-Trace");
      shared->order.created_at = nowString();
      shared->order.items.reserve(itemsJson.GetSize());

      for (const auto& itemJson : itemsJson) {
        const auto quantity = intField(itemJson, "quantity");
        if (quantity <= 0) {
          throw std::invalid_argument("all quantities must be positive");
        }
        const auto unitPrice =
            doubleField(itemJson, "unit_price", "unitPrice", 0.0);
        shared->order.items.push_back(
            example::model::types::OrderItem{
                shared->order.id,
                stringField(itemJson, "item_id", "itemId"),
                stringField(itemJson, "sku", "sku"),
                quantity,
                unitPrice,
            });
        shared->order.total_amount +=
            static_cast<double>(quantity) * unitPrice;
      }
      shared->expectedItems = shared->order.items.size();

      const auto deadline = std::chrono::steady_clock::now() + timeout_;
      if (!context.deadline() || deadline < *context.deadline()) {
        context = context.withDeadline(deadline);
      }
      return {std::move(context), State{std::move(shared)}};
    } catch (const std::exception& error) {
      data.response.SetStatus(
          userver::server::http::HttpStatus::kBadRequest);
      data.response.SetHeader(
          std::string_view{"Content-Type"}, std::string{"application/json"});
      data.setResponseBody(errorBody(error.what()));
      throw;
    }
  }

  void consumeMessage(
      servicelib::MessageContext context, auto& streamContext, State& state,
      servicelib::datasource::http::HandlerData&, auto resultContext) const {
    const auto shared = state.shared;
    resultContext.setResultCallback(
        shared->order.id,
        [resultContext, shared](
            servicelib::MessageContext, auto&, State&,
            const example::order_service::types::OrderState& value,
            servicelib::datasource::http::HandlerData& data) mutable {
          std::lock_guard lock(shared->mutex);
          if (shared->responseSent) {
            return true;
          }

          if (value.status != "TIMED_OUT") {
            shared->results.insert(
                shared->results.end(), value.confirmed_items.begin(),
                value.confirmed_items.end());
            if (shared->results.size() < shared->expectedItems) {
              return false;
            }
          }

          auto status = value.status;
          if (status != "TIMED_OUT") {
            status = std::all_of(
                         shared->results.begin(), shared->results.end(),
                         [](const auto& item) { return item.reserved; })
                         ? "CONFIRMED"
                         : "PARTIALLY_CONFIRMED";
          }

          double totalAmount = 0.0;
          for (const auto& item : shared->results) {
            totalAmount +=
                item.unit_price * static_cast<double>(item.requested_qty);
          }
          if (shared->results.empty()) {
            totalAmount = shared->order.total_amount;
          }

          data.response.SetStatus(userver::server::http::HttpStatus::kOk);
          data.response.SetHeader(
              std::string_view{"Content-Type"},
              std::string{"application/json"});
          data.setResponseBody(makeResponse(
              shared->order.id, status, shared->results, totalAmount));
          shared->responseSent = true;
          resultContext.done();
          return true;
        });

    streamContext.collect(std::move(context), shared->order);
  }

  std::string getMessageId(
      servicelib::MessageContext, auto&, State&,
      const example::order_service::types::OrderState& value) const {
    return value.order_id;
  }

  void endRequest(
      servicelib::MessageContext, auto&, std::exception_ptr error, State&,
      servicelib::datasource::http::HandlerData& data) const noexcept {
    if (!error || !data.responseBody.empty()) {
      return;
    }
    try {
      data.response.SetStatus(
          userver::server::http::HttpStatus::kInternalServerError);
      data.response.SetHeader(
          std::string_view{"Content-Type"}, std::string{"application/json"});
      data.setResponseBody(errorBody("internal server error"));
    } catch (...) {
      // EndRequest is noexcept by the datasource contract.
    }
  }

 private:
  static std::string stringField(
      const userver::formats::json::Value& object, std::string_view primary,
      std::string_view alternative, std::string defaultValue = {}) {
    if (const auto value = object[primary]; !value.IsMissing()) {
      return value.As<std::string>();
    }
    if (const auto value = object[alternative]; !value.IsMissing()) {
      return value.As<std::string>();
    }
    if (!defaultValue.empty() || primary == "customer_id") {
      return defaultValue;
    }
    throw std::invalid_argument("missing field: " + std::string{primary});
  }

  static std::int32_t intField(
      const userver::formats::json::Value& object, std::string_view name) {
    const auto value = object[name];
    if (value.IsMissing()) {
      throw std::invalid_argument("missing field: " + std::string{name});
    }
    return value.As<std::int32_t>();
  }

  static double doubleField(
      const userver::formats::json::Value& object, std::string_view primary,
      std::string_view alternative, double defaultValue) {
    if (const auto value = object[primary]; !value.IsMissing()) {
      return value.As<double>();
    }
    if (const auto value = object[alternative]; !value.IsMissing()) {
      return value.As<double>();
    }
    return defaultValue;
  }

  static std::string nowString() {
    return userver::utils::datetime::TimestampToString(std::time(nullptr));
  }

  static std::string makeResponse(
      const std::string& orderId, const std::string& status,
      const std::vector<example::model::types::OrderItemResult>& results,
      double totalAmount) {
    userver::formats::json::ValueBuilder json;
    json["order_id"] = orderId;
    json["status"] = status;
    json["total_amount"] = totalAmount;
    json["processed_at"] = nowString();
    json["confirmed_items"] =
        userver::formats::json::ValueBuilder{
            userver::formats::common::Type::kArray};
    for (const auto& result : results) {
      userver::formats::json::ValueBuilder item;
      item["item_id"] = result.item_id;
      item["sku"] = result.sku;
      item["available_qty"] = result.available_qty;
      item["reserved"] = result.reserved;
      item["status"] = result.status;
      json["confirmed_items"].PushBack(std::move(item));
    }
    return userver::formats::json::ToString(json.ExtractValue());
  }

  static std::string errorBody(std::string_view message) {
    userver::formats::json::ValueBuilder json;
    json["error"] = std::string{message};
    return userver::formats::json::ToString(json.ExtractValue());
  }

  std::chrono::steady_clock::duration timeout_;
};

}  // namespace example::order_service::functions
