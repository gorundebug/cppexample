#pragma once

#include <stdexcept>
#include <string>

#include <userver/formats/json.hpp>
#include <userver/formats/serialize/common_containers.hpp>
#include <userver/formats/serialize/to.hpp>

#include <servicelib/runtime/serde/serde.hpp>

#include <model/include/example/model/types/order_processed.hpp>

namespace example::model::types::serde {

// NOTE: reachable via servicelib::serde::MakeDefaultSerde<T>() (see
// serde_registration.generated.hpp), but cppservicelib's runtime does not
// yet call that for stream/pool values, so this class is not on any
// request path and is not exercised by benchmarks/profiling.
class OrderProcessedSerde final : public servicelib::serde::Serde<example::model::types::OrderProcessed> {
 public:
  bool IsStub() const noexcept override { return false; }

  servicelib::serde::SerdeData Serialize(
      const example::model::types::OrderProcessed& value) const override {
    servicelib::serde::SerdeData result;
    SerializeTo(result, value);
    return result;
  }

  void SerializeTo(servicelib::serde::SerdeData& output,
                   const example::model::types::OrderProcessed& value) const override {
    const auto json = userver::formats::json::ValueBuilder(value).ExtractValue();
    const auto text = userver::formats::json::ToString(json);
    const auto* bytes = reinterpret_cast<const std::byte*>(text.data());
    output.insert(output.end(), bytes, bytes + text.size());
  }

  example::model::types::OrderProcessed Deserialize(
      servicelib::serde::SerdeView data) const override {
    const auto* chars = reinterpret_cast<const char*>(data.data());
    return userver::formats::json::FromString(std::string{chars, data.size()})
        .As<example::model::types::OrderProcessed>();
  }
};

}  // namespace example::model::types::serde
