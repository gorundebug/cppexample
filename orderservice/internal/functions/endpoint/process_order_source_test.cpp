#include <functional>
#include <memory>
#include <optional>

#include <userver/server/http/http_request_builder.hpp>
#include <userver/utest/utest.hpp>

#include "orderservice/internal/functions/endpoint/process_order_source.hpp"

namespace example::order_service::functions {
namespace {
using Order = example::order_service::types::Order;
using OrderState = example::order_service::types::OrderState;
using HandlerData = servicelib::datasource::http::HandlerData;

struct Collector {
  std::optional<servicelib::Payload<Order>> received;
  void collect(servicelib::MessageContext, servicelib::Payload<Order> payload) {
    received.emplace(std::move(payload));
  }
};

struct CallbackState {
  std::function<bool(const OrderState&, HandlerData&)> callback;
  bool done{};
};

struct Results {
  std::shared_ptr<CallbackState> shared;
  template <typename Callback>
  void setResultCallback(const std::string&, Callback callback) {
    shared->callback = [callback = std::move(callback)](
                           const OrderState& value, HandlerData& data) mutable {
      int unused_stream = 0;
      ProcessOrderSource::State unused_state;
      return callback(servicelib::MessageContext{}, unused_stream, unused_state,
                      value, data);
    };
  }
  void done() { shared->done = true; }
};

constexpr auto kBody = R"({"customer_id":"customer","items":[
  {"item_id":"one","sku":"SKU-001","quantity":2,"unit_price":10},
  {"item_id":"two","sku":"missing","quantity":1,"unit_price":7}
]})";

UTEST(ProcessOrderSource, SharesOrderAndPreservesAggregatedResponse) {
  ProcessOrderSource handler;
  Collector stream;
  auto request = userver::server::http::HttpRequestBuilder{}
                     .SetMethod(userver::server::http::HttpMethod::kPost)
                     .AddHeader("X-Request-ID", "order-123")
                     .SetBody(std::string{kBody})
                     .Build();
  HandlerData data{*request, request->GetHttpResponse(), {}};
  auto begin = handler.beginRequest(servicelib::MessageContext{}, stream, data);
  const Order* original = &begin.state.shared->order->get();
  const auto* original_items = original->items.data();
  auto result = std::make_shared<CallbackState>();
  handler.consumeMessage(begin.context, stream, begin.state, data,
                         Results{result});
  ASSERT_TRUE(stream.received);
  EXPECT_EQ(&stream.received->get(), original);
  EXPECT_EQ(stream.received->get().items.data(), original_items);
  EXPECT_EQ(stream.received->get().items.size(), 2);
  // The callback must retain the order even after the source state and graph
  // have released it. In particular, id and total must not be moved from.
  begin.state.shared.reset();
  stream.received.reset();
  OrderState first{
      "order-123",
      "CONFIRMED",
      {{"order-123", "one", "SKU-001", 2, 2, true, "CONFIRMED", 10, {}}},
      20,
      {}};
  EXPECT_FALSE(result->callback(first, data));
  EXPECT_FALSE(result->done);
  OrderState second{
      "order-123",
      "OUT_OF_STOCK",
      {{"order-123", "two", "missing", 1, 0, false, "OUT_OF_STOCK", 7, {}}},
      7,
      {}};
  EXPECT_TRUE(result->callback(second, data));
  EXPECT_TRUE(result->done);
  const auto json = userver::formats::json::FromString(data.responseBody);
  EXPECT_EQ(json["order_id"].As<std::string>(), "order-123");
  EXPECT_EQ(json["status"].As<std::string>(), "PARTIALLY_CONFIRMED");
  EXPECT_EQ(json["total_amount"].As<double>(), 27);
  EXPECT_EQ(json["confirmed_items"].GetSize(), 2);
  const auto response = data.responseBody;
  EXPECT_TRUE(result->callback(second, data));
  EXPECT_EQ(data.responseBody, response);
  result->callback = {};  // production endpoint unregisters its callback too
}

UTEST(ProcessOrderSource, TimeoutKeepsOrderIdAndOriginalTotal) {
  ProcessOrderSource handler;
  Collector stream;
  auto request = userver::server::http::HttpRequestBuilder{}
                     .AddHeader("X-Request-ID", "order-timeout")
                     .SetBody(std::string{kBody})
                     .Build();
  HandlerData data{*request, request->GetHttpResponse(), {}};
  auto begin = handler.beginRequest(servicelib::MessageContext{}, stream, data);
  auto result = std::make_shared<CallbackState>();
  handler.consumeMessage(begin.context, stream, begin.state, data,
                         Results{result});
  begin.state.shared.reset();
  stream.received.reset();
  OrderState timeout{"order-timeout", "TIMED_OUT", {}, 0, {}};
  EXPECT_TRUE(result->callback(timeout, data));
  const auto json = userver::formats::json::FromString(data.responseBody);
  EXPECT_EQ(json["order_id"].As<std::string>(), "order-timeout");
  EXPECT_EQ(json["status"].As<std::string>(), "TIMED_OUT");
  EXPECT_EQ(json["total_amount"].As<double>(), 27);
  EXPECT_TRUE(result->done);
  result->callback = {};
}
}  // namespace
}  // namespace example::order_service::functions
