#pragma once

#include <stdexcept>
#include <string>

#include <userver/formats/json.hpp>
#include <userver/formats/serialize/common_containers.hpp>
#include <userver/formats/serialize/to.hpp>

#include <servicelib/runtime/serde/serde.hpp>

#include <model_cpp/include/example/model/types/automation_job.hpp>

namespace example::model::types::serde {

// NOTE: reachable via servicelib::serde::MakeDefaultSerde<T>() (see
// serde_registration.generated.hpp), but cppservicelib's runtime does not
// yet call that for stream/pool values, so this class is not on any
// request path and is not exercised by benchmarks/profiling.
class AutomationJobSerde final : public servicelib::serde::Serde<example::model::types::AutomationJob> {
 public:
  bool IsStub() const noexcept override { return false; }

  servicelib::serde::SerdeData Serialize(
      const example::model::types::AutomationJob& value) const override {
    servicelib::serde::SerdeData result;
    SerializeTo(result, value);
    return result;
  }

  void SerializeTo(servicelib::serde::SerdeData& output,
                    const example::model::types::AutomationJob& value) const override {
    const auto json = userver::formats::json::ValueBuilder(value).ExtractValue();
    const auto text = userver::formats::json::ToString(json);
    const auto* bytes = reinterpret_cast<const std::byte*>(text.data());
    output.insert(output.end(), bytes, bytes + text.size());
  }

  example::model::types::AutomationJob Deserialize(
      servicelib::serde::SerdeView data) const override {
    const auto* chars = reinterpret_cast<const char*>(data.data());
    const std::string text(chars, data.size());
    return userver::formats::json::FromString(text).As<example::model::types::AutomationJob>();
  }
};

}  // namespace example::model::types::serde