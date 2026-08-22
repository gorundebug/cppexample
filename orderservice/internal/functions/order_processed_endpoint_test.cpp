#include <concepts>

#include <userver/utest/utest.hpp>

#include "orderservice/internal/functions/order_processed_endpoint.hpp"

namespace example::order_service::functions {

UTEST(OrderProcessedEndpoint, Contract) {
  static_assert(std::default_initializable<OrderProcessedEndpoint>);
  GTEST_SKIP() << "TODO: add behavior assertions for OrderProcessed";
}

}  // namespace example::order_service::functions
