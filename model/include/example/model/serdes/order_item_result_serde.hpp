#pragma once

#include <string>

#include <userver/formats/json.hpp>
#include <userver/formats/serialize/common_containers.hpp>
#include <userver/formats/serialize/to.hpp>

#include <servicelib/runtime/serde/serde.hpp>

#include <model/include/example/model/types/order_item_result.hpp>

namespace example::model::types::serde {

class OrderItemResultSerde final : public servicelib::serde::Serde<example::model::types::OrderItemResult> {
 public:
  bool IsStub() const noexcept override { return false; }

  servicelib::serde::SerdeData Serialize(
      const example::model::types::OrderItemResult& value) const override {
    servicelib::serde::SerdeData result;
    SerializeTo(result, value);
    return result;
  }

  void SerializeTo(servicelib::serde::SerdeData& output,
                    const example::model::types::OrderItemResult& value) const override {
    const auto json = userver::formats::json::ValueBuilder(value).ExtractValue();
    const auto text = userver::formats::json::ToString(json);
    const auto* bytes = reinterpret_cast<const std::byte*>(text.data());
    output.insert(output.end(), bytes, bytes + text.size());
  }

  example::model::types::OrderItemResult Deserialize(
      servicelib::serde::SerdeView data) const override {
    const auto* chars = reinterpret_cast<const char*>(data.data());
    const std::string text(chars, data.size());
    return userver::formats::json::FromString(text).As<example::model::types::OrderItemResult>();
  }
};

}  // namespace example::model::types::serde
