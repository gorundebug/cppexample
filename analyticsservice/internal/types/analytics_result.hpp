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

namespace example::analytics_service::types {

struct AnalyticsResult final {
  std::string key;
  std::int64_t total{0};
  std::string kind;
};

inline AnalyticsResult Parse(const userver::formats::json::Value& json,
                             userver::formats::parse::To<AnalyticsResult>) {
  return {json["key"].As<std::string>(), json["total"].As<std::int64_t>(),
          json["kind"].As<std::string>()};
}

inline userver::formats::json::Value Serialize(
    const AnalyticsResult& value,
    userver::formats::serialize::To<userver::formats::json::Value>) {
  userver::formats::json::ValueBuilder json;
  json["key"] = value.key;
  json["total"] = value.total;
  json["kind"] = value.kind;
  return json.ExtractValue();
}

}  // namespace example::analytics_service::types
