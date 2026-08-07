#pragma once

#include <cstddef>
#include <cstdint>
#include <string>
#include <unordered_map>
#include <vector>

#include <userver/formats/json/value.hpp>
#include <userver/formats/json/value_builder.hpp>
#include <userver/formats/serialize/to.hpp>

namespace example::model::types {

struct OrderItem final {
  std::string order_id;
  std::string item_id;
  std::string sku;
  std::int32_t quantity{0};
  double unit_price{0.0};
};

inline OrderItem Parse(
    const userver::formats::json::Value& json,
    userver::formats::parse::To<OrderItem>) {
  return {
      json["order_id"].As<std::string>(),
      json["item_id"].As<std::string>(),
      json["sku"].As<std::string>(),
      json["quantity"].As<std::int32_t>(),
      json["unit_price"].As<double>(),
  };
}

inline userver::formats::json::Value Serialize(
    const OrderItem& value,
    userver::formats::serialize::To<userver::formats::json::Value>) {
  userver::formats::json::ValueBuilder json;
  json["order_id"] = value.order_id;
  json["item_id"] = value.item_id;
  json["sku"] = value.sku;
  json["quantity"] = value.quantity;
  json["unit_price"] = value.unit_price;
  return json.ExtractValue();
}

}  // namespace example::model::types
