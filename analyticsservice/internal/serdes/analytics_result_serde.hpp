#pragma once

#include <stdexcept>
#include <string>

#include <userver/formats/json.hpp>
#include <userver/formats/serialize/common_containers.hpp>
#include <userver/formats/serialize/to.hpp>

#include <servicelib/runtime/serde/serde.hpp>

#include <analyticsservice/internal/types/analytics_result.hpp>

namespace example::analytics_service::types::serde {

// NOTE: reachable via servicelib::serde::MakeDefaultSerde<T>() (see
// serde_registration.generated.hpp), but cppservicelib's runtime does not
// yet call that for stream/pool values, so this class is not on any
// request path and is not exercised by benchmarks/profiling.
class AnalyticsResultSerde final : public servicelib::serde::Serde<example::analytics_service::types::AnalyticsResult> {
 public:
  bool IsStub() const noexcept override { return true; }

  servicelib::serde::SerdeData Serialize(
      const example::analytics_service::types::AnalyticsResult&) const override {
    throw std::runtime_error("serde for example::analytics_service::types::AnalyticsResult is not implemented");
  }

  void SerializeTo(servicelib::serde::SerdeData&,
                   const example::analytics_service::types::AnalyticsResult&) const override {
    throw std::runtime_error("serde for example::analytics_service::types::AnalyticsResult is not implemented");
  }

  example::analytics_service::types::AnalyticsResult Deserialize(
      servicelib::serde::SerdeView) const override {
    throw std::runtime_error("serde for example::analytics_service::types::AnalyticsResult is not implemented");
  }
};

}  // namespace example::analytics_service::types::serde