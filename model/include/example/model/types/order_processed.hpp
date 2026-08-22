#pragma once

#include <cstddef>
#include <cstdint>
#include <string>
#include <unordered_map>
#include <vector>

#include <userver/formats/json/value.hpp>
#include <userver/formats/json/value_builder.hpp>
#include <userver/formats/parse/to.hpp>
#include <userver/formats/serialize/to.hpp>

namespace example::model::types {

struct OrderProcessed final {
  std::string order_id;
  std::string status;
  std::string processed_at;
  std::size_t total_items{};
  std::size_t confirmed_items{};
  std::string failure_reason;
};

inline OrderProcessed Parse(
    const userver::formats::json::Value& json,
    userver::formats::parse::To<OrderProcessed>) {
  return {
      json["order_id"].As<std::string>(),
      json["status"].As<std::string>(),
      json["processed_at"].As<std::string>(),
      json["total_items"].As<std::size_t>(),
      json["confirmed_items"].As<std::size_t>(),
      json["failure_reason"].As<std::string>(),
  };
}

inline userver::formats::json::Value Serialize(
    const OrderProcessed& value,
    userver::formats::serialize::To<userver::formats::json::Value>) {
  userver::formats::json::ValueBuilder json;
  json["order_id"] = value.order_id;
  json["status"] = value.status;
  json["processed_at"] = value.processed_at;
  json["total_items"] = value.total_items;
  json["confirmed_items"] = value.confirmed_items;
  json["failure_reason"] = value.failure_reason;
  return json.ExtractValue();
}

}  // namespace example::model::types
