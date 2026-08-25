#include <gtest/gtest.h>

#include "orderservice/internal/functions/process_order.hpp"

namespace example::order_service::functions {

namespace {
struct StreamContext final {};
}  // namespace

TEST(ProcessOrder, CorrelatesStatesByOrderId) {
  ProcessOrder function;
  StreamContext stream;
  ProcessOrder::State state;
  const auto id = function.getMessageId(
      servicelib::MessageContext{}, stream, state,
      example::order_service::types::OrderState{
          "order-9", "CONFIRMED", {}, 0.0, {}});
  EXPECT_EQ(id, "order-9");
}

}  // namespace example::order_service::functions
