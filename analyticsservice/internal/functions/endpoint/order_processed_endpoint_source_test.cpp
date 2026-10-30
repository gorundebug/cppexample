#include <concepts>

#include <gtest/gtest.h>

#include "analyticsservice/internal/functions/endpoint/order_processed_endpoint_source.hpp"

namespace example::analytics_service::functions {

struct TransportErrorStream {
  std::exception_ptr error;
  void collectError(servicelib::MessageContext, std::exception_ptr value) {
    error = std::move(value);
  }
};

TEST(OrderProcessedEndpointSource, Contract) {
  static_assert(std::default_initializable<OrderProcessedEndpointSource>);
  TransportErrorStream stream;
  const auto error = std::make_exception_ptr(std::runtime_error("broker unavailable"));
  OrderProcessedEndpointSource{}.onError(servicelib::MessageContext{}, stream, error);
  EXPECT_EQ(stream.error, error);
}

}  // namespace example::analytics_service::functions
