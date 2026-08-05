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

struct OrderItemResult final {
  std::string order_id;
  std::string item_id;
  std::string sku;
  std::int32_t requested_qty{0};
  std::int32_t available_qty{0};
  bool reserved{false};
  std::string status;
  double unit_price{0.0};
  std::string error;
};

inline OrderItemResult Parse(
    const userver::formats::json::Value& json,
    userver::formats::parse::To<OrderItemResult>) {
  return {
      json["order_id"].As<std::string>(),
      json["item_id"].As<std::string>(),
      json["sku"].As<std::string>(),
      json["requested_qty"].As<std::int32_t>(),
      json["available_qty"].As<std::int32_t>(),
      json["reserved"].As<bool>(),
      json["status"].As<std::string>(),
      json["unit_price"].As<double>(),
      json["error"].As<std::string>(""),
  };
}

inline userver::formats::json::Value Serialize(
    const OrderItemResult& value,
    userver::formats::serialize::To<userver::formats::json::Value>) {
  userver::formats::json::ValueBuilder json;
  json["order_id"] = value.order_id;
  json["item_id"] = value.item_id;
  json["sku"] = value.sku;
  json["requested_qty"] = value.requested_qty;
  json["available_qty"] = value.available_qty;
  json["reserved"] = value.reserved;
  json["status"] = value.status;
  json["unit_price"] = value.unit_price;
  json["error"] = value.error;
  return json.ExtractValue();
}

}  // namespace example::model::types
