#pragma once

#include <cstddef>
#include <cstdint>
#include <string>
#include <unordered_map>
#include <vector>

#include <userver/formats/json/value.hpp>
#include <userver/formats/json/value_builder.hpp>
#include <userver/formats/parse/common_containers.hpp>
#include <userver/formats/serialize/common_containers.hpp>
#include <userver/formats/serialize/to.hpp>

#include <model/include/example/model/types/order_item.hpp>

namespace example::order_service::types {

struct Order final {
  std::string id;
  std::string customer_id;
  std::vector<example::model::types::OrderItem> items;
  double total_amount{0.0};
  std::string created_at;
  std::string trace_id;
};

inline Order Parse(
    const userver::formats::json::Value& json,
    userver::formats::parse::To<Order>) {
  return {
      json["id"].As<std::string>(),
      json["customer_id"].As<std::string>(),
      json["items"].As<std::vector<example::model::types::OrderItem>>(),
      json["total_amount"].As<double>(),
      json["created_at"].As<std::string>(),
      json["trace_id"].As<std::string>(),
  };
}

inline userver::formats::json::Value Serialize(
    const Order& value,
    userver::formats::serialize::To<userver::formats::json::Value>) {
  userver::formats::json::ValueBuilder json;
  json["id"] = value.id;
  json["customer_id"] = value.customer_id;
  json["items"] = value.items;
  json["total_amount"] = value.total_amount;
  json["created_at"] = value.created_at;
  json["trace_id"] = value.trace_id;
  return json.ExtractValue();
}

}  // namespace example::order_service::types
