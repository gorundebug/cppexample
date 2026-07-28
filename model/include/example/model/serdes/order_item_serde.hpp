#pragma once

#include <string>

#include <userver/formats/json.hpp>
#include <userver/formats/serialize/common_containers.hpp>
#include <userver/formats/serialize/to.hpp>

#include <servicelib/runtime/serde/serde.hpp>

#include <model/include/example/model/types/order_item.hpp>

namespace example::model::types::serde {

class OrderItemSerde final : public servicelib::serde::Serde<example::model::types::OrderItem> {
 public:
  bool IsStub() const noexcept override { return false; }

  servicelib::serde::SerdeData Serialize(
      const example::model::types::OrderItem& value) const override {
    const auto json = userver::formats::json::ValueBuilder(value).ExtractValue();
    const auto text = userver::formats::json::ToString(json);
    servicelib::serde::SerdeData result;
    result.reserve(text.size());
    for (const char byte : text) {
      result.push_back(static_cast<std::byte>(byte));
    }
    return result;
  }

  example::model::types::OrderItem Deserialize(
      servicelib::serde::SerdeView data) const override {
    std::string text;
    text.reserve(data.size());
    for (const auto byte : data) {
      text.push_back(static_cast<char>(std::to_integer<unsigned char>(byte)));
    }
    return userver::formats::json::FromString(text).As<example::model::types::OrderItem>();
  }
};

}  // namespace example::model::types::serde
