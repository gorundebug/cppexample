#pragma once

#include <string>

#include <userver/formats/json.hpp>
#include <userver/formats/serialize/common_containers.hpp>
#include <userver/formats/serialize/to.hpp>

#include <servicelib/runtime/serde/serde.hpp>

#include <orderservice/internal/types/order_state.hpp>

namespace example::order_service::types::serde {

// NOTE: generated but currently unused. servicegen's C++ codegen has no
// equivalent of the Go port's Service.GetSerde() dispatch yet, so nothing
// constructs or calls this class -- it is not on any request path and is
// not exercised by benchmarks/profiling.
class OrderStateSerde final : public servicelib::serde::Serde<example::order_service::types::OrderState> {
 public:
  bool IsStub() const noexcept override { return false; }

  servicelib::serde::SerdeData Serialize(
      const example::order_service::types::OrderState& value) const override {
    servicelib::serde::SerdeData result;
    SerializeTo(result, value);
    return result;
  }

  void SerializeTo(servicelib::serde::SerdeData& output,
                    const example::order_service::types::OrderState& value) const override {
    const auto json = userver::formats::json::ValueBuilder(value).ExtractValue();
    const auto text = userver::formats::json::ToString(json);
    const auto* bytes = reinterpret_cast<const std::byte*>(text.data());
    output.insert(output.end(), bytes, bytes + text.size());
  }

  example::order_service::types::OrderState Deserialize(
      servicelib::serde::SerdeView data) const override {
    const auto* chars = reinterpret_cast<const char*>(data.data());
    const std::string text(chars, data.size());
    return userver::formats::json::FromString(text).As<example::order_service::types::OrderState>();
  }
};

}  // namespace example::order_service::types::serde
