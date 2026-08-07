#pragma once

#include <cstddef>
#include <cstdint>
#include <string>
#include <unordered_map>
#include <vector>

#include <userver/formats/json/value.hpp>
#include <userver/formats/json/value_builder.hpp>
#include <userver/formats/parse/common_containers.hpp>
#include <userver/formats/serialize/common_containers.hpp>
#include <userver/formats/serialize/to.hpp>

#include <model/include/example/model/types/order_item_result.hpp>

namespace example::order_service::types {

struct OrderState final {
  std::string order_id;
  std::string status;
  std::vector<example::model::types::OrderItemResult> confirmed_items;
  double total_amount{0.0};
  std::string processed_at;
};

inline OrderState Parse(
    const userver::formats::json::Value& json,
    userver::formats::parse::To<OrderState>) {
  return {
      json["order_id"].As<std::string>(),
      json["status"].As<std::string>(),
      json["confirmed_items"]
          .As<std::vector<example::model::types::OrderItemResult>>(),
      json["total_amount"].As<double>(),
      json["processed_at"].As<std::string>(),
  };
}

inline userver::formats::json::Value Serialize(
    const OrderState& value,
    userver::formats::serialize::To<userver::formats::json::Value>) {
  userver::formats::json::ValueBuilder json;
  json["order_id"] = value.order_id;
  json["status"] = value.status;
  json["confirmed_items"] = value.confirmed_items;
  json["total_amount"] = value.total_amount;
  json["processed_at"] = value.processed_at;
  return json.ExtractValue();
}

}  // namespace example::order_service::types
