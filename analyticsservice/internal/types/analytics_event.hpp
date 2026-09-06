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

struct AnalyticsEvent final {
  std::string key;
  std::int64_t value{0};
  std::string kind;
};

inline AnalyticsEvent Parse(const userver::formats::json::Value& json,
                            userver::formats::parse::To<AnalyticsEvent>) {
  return {json["key"].As<std::string>(), json["value"].As<std::int64_t>(),
          json["kind"].As<std::string>()};
}

inline userver::formats::json::Value Serialize(
    const AnalyticsEvent& value,
    userver::formats::serialize::To<userver::formats::json::Value>) {
  userver::formats::json::ValueBuilder json;
  json["key"] = value.key;
  json["value"] = value.value;
  json["kind"] = value.kind;
  return json.ExtractValue();
}

}  // namespace example::analytics_service::types
