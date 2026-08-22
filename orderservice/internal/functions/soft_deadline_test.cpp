#include <chrono>

#include <userver/utest/utest.hpp>

#include "orderservice/internal/functions/soft_deadline.hpp"
#include "orderservice/internal/functions/test_stream.hpp"

namespace example::order_service::functions {

UTEST(SoftDeadline, UsesConfiguredMarginWithoutRequestDeadline) {
  using namespace std::chrono_literals;
  SoftDeadline function{125ms};
  test::Stream stream;
  const auto delay = function(
      servicelib::MessageContext{},
      stream,
      example::order_service::types::Order{});
  EXPECT_EQ(delay, 125ms);
}

UTEST(SoftDeadline, FiresBeforeRequestDeadline) {
  using namespace std::chrono_literals;
  SoftDeadline function{100ms};
  test::Stream stream;
  const auto context = servicelib::MessageContext{}.withDeadline(
      std::chrono::steady_clock::now() + 500ms);
  const auto delay =
      function(context, stream, example::order_service::types::Order{});
  EXPECT_GE(delay, 350ms);
  EXPECT_LE(delay, 400ms);
}

}  // namespace example::order_service::functions
