#pragma once

#include <stdexcept>
#include <string>

#include <userver/formats/json.hpp>
#include <userver/formats/serialize/common_containers.hpp>
#include <userver/formats/serialize/to.hpp>

#include <servicelib/runtime/serde/serde.hpp>

#include <model_cpp/include/example/model/types/order_item.hpp>

namespace example::model::types::serde {

// NOTE: reachable via servicelib::serde::MakeDefaultSerde<T>() (see
// serde_registration.generated.hpp), but cppservicelib's runtime does not
// yet call that for stream/pool values, so this class is not on any
// request path and is not exercised by benchmarks/profiling.
class OrderItemSerde final : public servicelib::serde::Serde<example::model::types::OrderItem> {
 public:
  bool IsStub() const noexcept override { return false; }

  servicelib::serde::SerdeData Serialize(
      const example::model::types::OrderItem& value) const override {
    servicelib::serde::SerdeData result;
    SerializeTo(result, value);
    return result;
  }

  void SerializeTo(servicelib::serde::SerdeData& output,
                   const example::model::types::OrderItem& value) const override {
    const auto text = userver::formats::json::ToString(
        userver::formats::json::ValueBuilder(value).ExtractValue());
    const auto* bytes = reinterpret_cast<const std::byte*>(text.data());
    output.insert(output.end(), bytes, bytes + text.size());
  }

  example::model::types::OrderItem Deserialize(
      servicelib::serde::SerdeView data) const override {
    const auto* chars = reinterpret_cast<const char*>(data.data());
    return userver::formats::json::FromString(std::string{chars, data.size()})
        .As<example::model::types::OrderItem>();
  }
};

}  // namespace example::model::types::serde
