#pragma once

#include <chrono>
#include <cstddef>
#include <stdexcept>
#include <tuple>
#include <utility>
#include <vector>

#include "runtime/context.hpp"
#include <orderservice/internal/types/order.hpp>
#include <orderservice/internal/types/order_state.hpp>


namespace example::order_service::functions {

// User-owned callable. Its operator is checked by servicelib::StreamFunction
// when the generated stream graph binds it to an operator.
struct MapToOrderState final {
  template <typename... Outputs>
  void operator()(servicelib::MessageContext context,
                  const example::order_service::types::Order& value,
                  Outputs&&... outputs) const {
    auto collectors = std::forward_as_tuple(outputs...);
    std::get<0>(collectors).out(
        std::move(context),
        example::order_service::types::OrderState{
            value.id,
            "TIMED_OUT",
            {},
            value.total_amount,
            {},
        });
  }
};

}  // namespace example::order_service::functions
