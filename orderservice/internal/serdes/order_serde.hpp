#pragma once

#include <string>

#include <userver/formats/json.hpp>
#include <userver/formats/serialize/common_containers.hpp>
#include <userver/formats/serialize/to.hpp>

#include <servicelib/runtime/serde/serde.hpp>

#include <orderservice/internal/types/order.hpp>

namespace example::order_service::types::serde {

// NOTE: reachable via servicelib::serde::MakeDefaultSerde<T>() (see
// serde_registration.generated.hpp), but cppservicelib's runtime does not
// yet call that for stream/pool values, so this class is not on any
// request path and is not exercised by benchmarks/profiling.
class OrderSerde final : public servicelib::serde::Serde<example::order_service::types::Order> {
 public:
  bool IsStub() const noexcept override { return false; }

  servicelib::serde::SerdeData Serialize(
      const example::order_service::types::Order& value) const override {
    servicelib::serde::SerdeData result;
    SerializeTo(result, value);
    return result;
  }

  void SerializeTo(servicelib::serde::SerdeData& output,
                    const example::order_service::types::Order& value) const override {
    const auto json = userver::formats::json::ValueBuilder(value).ExtractValue();
    const auto text = userver::formats::json::ToString(json);
    const auto* bytes = reinterpret_cast<const std::byte*>(text.data());
    output.insert(output.end(), bytes, bytes + text.size());
  }

  example::order_service::types::Order Deserialize(
      servicelib::serde::SerdeView data) const override {
    const auto* chars = reinterpret_cast<const char*>(data.data());
    const std::string text(chars, data.size());
    return userver::formats::json::FromString(text).As<example::order_service::types::Order>();
  }
};

}  // namespace example::order_service::types::serde
