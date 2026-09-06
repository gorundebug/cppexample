#pragma once

#include <exception>
#include <memory>
#include <stdexcept>
#include <string>
#include <utility>
#include <variant>

#include <servicelib/runtime/common.hpp>
#include <servicelib/runtime/config/endpoint_types.hpp>
#include <servicelib/runtime/environment/environment.hpp>
#include <userver/engine/task/task_with_result.hpp>
#include <userver/utils/async.hpp>
#include <servicelib/datasource/localsource/custom.hpp>
#include <analyticsservice/internal/types/analytics_event.hpp>


namespace example::analytics_service::functions {

struct AnalyticsShipmentsSource final
    : public servicelib::datasource::localsource::DataProducer<
          example::analytics_service::types::AnalyticsEvent> {
  using State = std::monostate;

  void start(
      servicelib::Context,
      typename servicelib::datasource::localsource::DataProducer<
          example::analytics_service::types::AnalyticsEvent>::Consumer consumer) override {
    using Event = example::analytics_service::types::AnalyticsEvent;
    consumer(servicelib::MessageContext{},
             servicelib::Payload<Event>::make(Event{"high-value", 30, "shipment"}));
    consumer(servicelib::MessageContext{},
             servicelib::Payload<Event>::make(Event{"standard", 3, "shipment"}));
  }

  void stop(servicelib::Context) override {}

  int concurrency(auto&) const noexcept { return 0; }

  servicelib::BeginResult<State> beginRequest(
      servicelib::MessageContext context, auto&) const {
    return {std::move(context), {}};
  }

  void consumeMessage(
      servicelib::MessageContext context, auto& stream, State&,
      const example::analytics_service::types::AnalyticsEvent& value,
      auto result) const {
    stream.collect(std::move(context), value);
    result.done();
  }

  std::string getMessageId(
      servicelib::MessageContext, auto&, State&,
      const std::monostate&) const {
    return {};
  }

  void endRequest(
      servicelib::MessageContext, auto&, std::exception_ptr,
      State&) const noexcept {}
};

inline userver::engine::TaskWithResult<std::unique_ptr<AnalyticsShipmentsSource>> MakeAnalyticsShipmentsSource(
    servicelib::Context context, servicelib::IServiceEnvironment& environment,
    const servicelib::config::CustomEndpointConfig& config) {
  return userver::utils::Async(
      "make-analytics_shipments_source", [context = std::move(context), &environment,
                             config]() mutable {
        (void)context;
        (void)config;
        (void)environment;
        return std::make_unique<AnalyticsShipmentsSource>();
      });
}

}  // namespace example::analytics_service::functions
