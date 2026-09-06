#pragma once

#include <chrono>
#include <cstddef>
#include <memory>
#include <stdexcept>
#include <tuple>
#include <utility>
#include <vector>

#include <servicelib/runtime/context.hpp>
#include <servicelib/runtime/base.hpp>
#include <servicelib/runtime/config/stream_types.hpp>
#include <servicelib/runtime/environment/environment.hpp>
#include <userver/engine/task/task_with_result.hpp>
#include <userver/utils/async.hpp>
#include <analyticsservice/internal/types/analytics_event.hpp>
#include <analyticsservice/internal/types/analytics_key.hpp>
#include <analyticsservice/internal/types/analytics_result.hpp>


namespace example::analytics_service::functions {

// User-owned callable. Its operator is checked by servicelib::StreamFunction
// when the generated stream graph binds it to an operator.
struct MultiJoinAnalyticsEvents final {
  template <typename Values, typename Output>
  bool operator()(servicelib::MessageContext context,
                  servicelib::StreamBase& stream,
                  std::string& key,
                  Values& values,
                  Output&& out) const {
    (void)stream;
    const auto& orders = std::get<0>(values);
    const auto& payments = std::get<1>(values);
    const auto& shipments = std::get<2>(values);
    if (orders.empty() || payments.empty() || shipments.empty()) return false;
    std::forward<Output>(out).out(
        std::move(context),
        example::analytics_service::types::AnalyticsResult{
            key, orders.front().value + payments.front().value +
                     shipments.front().value,
            "multi"});
    return true;
  }
};

inline userver::engine::TaskWithResult<std::unique_ptr<MultiJoinAnalyticsEvents>> MakeMultiJoinAnalyticsEvents(
    servicelib::Context context, servicelib::IServiceEnvironment& environment,
    const servicelib::config::MultiJoinStreamConfig& config) {
  return userver::utils::Async(
      "make-multi_join_analytics_events", [context = std::move(context), &environment,
                             config]() mutable {
        (void)context;
        (void)environment;
        (void)config;
        return std::make_unique<MultiJoinAnalyticsEvents>();
      });
}

}  // namespace example::analytics_service::functions
