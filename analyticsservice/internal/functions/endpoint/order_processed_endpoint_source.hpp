#pragma once

#include <memory>

#include <userver/engine/task/task_with_result.hpp>
#include <userver/utils/async.hpp>

#include <exception>
#include <stdexcept>
#include <string>
#include <utility>
#include <variant>

#include <userver/formats/json/serialize.hpp>

#include <servicelib/runtime/common.hpp>
#include <servicelib/runtime/config/endpoint_types.hpp>
#include <servicelib/runtime/environment/environment.hpp>
#include <servicelib/datasource/kafka/userver.hpp>
#include <model_cpp/include/example/model/types/order_processed.hpp>


namespace example::analytics_service::functions {

struct OrderProcessedEndpointSource final {
  using State = std::monostate;

  int concurrency(auto&) const noexcept { return 0; }

  servicelib::BeginResult<State> beginRequest(
      servicelib::MessageContext context, auto&) const {
    return {std::move(context), {}};
  }

  void consumeMessage(
      servicelib::MessageContext context, auto& stream, State&,
      const servicelib::datasource::kafka::ConsumerMessage& message,
      auto result) const {
    auto value = userver::formats::json::FromString(message.value())
                     .template As<
                         example::model::types::OrderProcessed>();
    const auto message_id = value.order_id;
    result.setResultCallback(
        message_id,
        [message, result](servicelib::MessageContext, auto&, State&,
                          const auto&) mutable {
          message.commit();
          result.done();
          return true;
        });
    stream.collect(std::move(context), std::move(value));
  }

  std::string getMessageId(
      servicelib::MessageContext, auto&, State&,
      const example::model::types::OrderProcessed& value) const {
    return value.order_id;
  }

  void endRequest(
      servicelib::MessageContext, auto&, std::exception_ptr,
      State&) const noexcept {}
};

inline userver::engine::TaskWithResult<std::unique_ptr<OrderProcessedEndpointSource>> MakeOrderProcessedEndpointSource(
    servicelib::Context context, servicelib::IServiceEnvironment& environment,
    const servicelib::config::KafkaEndpointConfig& config) {
  return userver::utils::Async(
      "maker-MakeOrderProcessedEndpointSource", [context = std::move(context), &environment, config]() mutable {
  (void)context; (void)environment; (void)config;
  return std::make_unique<OrderProcessedEndpointSource>();
      });
}

}  // namespace example::analytics_service::functions
