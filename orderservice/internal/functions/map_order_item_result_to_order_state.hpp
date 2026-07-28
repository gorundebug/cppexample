#pragma once

#include <chrono>
#include <cstddef>
#include <stdexcept>
#include <tuple>
#include <utility>
#include <vector>

#include <servicelib/runtime/context.hpp>
#include <model/include/example/model/types/order_item_result.hpp>
#include <orderservice/internal/types/order_state.hpp>


namespace example::order_service::functions {

// User-owned callable. Its operator is checked by servicelib::StreamFunction
// when the generated stream graph binds it to an operator.
struct MapOrderItemResultToOrderState final {
  template <typename... Outputs>
  void operator()(servicelib::MessageContext context,
                  const example::model::types::OrderItemResult& value,
                  Outputs&&... outputs) const {
    auto collectors = std::forward_as_tuple(outputs...);
    std::get<0>(collectors).out(
        std::move(context),
        example::order_service::types::OrderState{
            value.order_id,
            value.reserved ? "CONFIRMED" : "PARTIALLY_CONFIRMED",
            {value},
            0.0,
            {},
        });
  }
};

}  // namespace example::order_service::functions
