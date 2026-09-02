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
#include <userver/formats/json/value_builder.hpp>

#include <servicelib/runtime/common.hpp>
#include <servicelib/runtime/config/endpoint_types.hpp>
#include <servicelib/runtime/environment/environment.hpp>
#include <servicelib/datasink/kafka/userver.hpp>
#include <model_cpp/include/example/model/types/order_processed.hpp>


namespace example::order_service::functions {

struct OrderProcessedEndpointSink final {
  using State = std::monostate;

  std::string getStreamId(
      servicelib::MessageContext,
      const example::model::types::OrderProcessed& value) const {
    return value.order_id;
  }

  servicelib::BeginResult<State> beginRequest(
      servicelib::MessageContext context, auto&) const {
    return {std::move(context), {}};
  }

  void consumeMessage(
      servicelib::MessageContext, auto&, State&,
      const example::model::types::OrderProcessed& value,
      servicelib::datasink::kafka::SinkMessage<std::monostate>& message) const {
    message.key = value.order_id;
    message.value = userver::formats::json::ToString(
        userver::formats::json::ValueBuilder{value}.ExtractValue());
    message.send([](const auto&) { return std::monostate{}; });
  }

  void endRequest(
      servicelib::MessageContext, auto&, std::exception_ptr,
      State&) const noexcept {}
};

inline userver::engine::TaskWithResult<std::unique_ptr<OrderProcessedEndpointSink>> MakeOrderProcessedEndpointSink(
    servicelib::Context context, servicelib::IServiceEnvironment& environment,
    const servicelib::config::KafkaEndpointConfig& config) {
  return userver::utils::Async(
      "maker-MakeOrderProcessedEndpointSink", [context = std::move(context), &environment, config]() mutable {
  (void)context; (void)environment; (void)config;
  return std::make_unique<OrderProcessedEndpointSink>();
      });
}

}  // namespace example::order_service::functions
