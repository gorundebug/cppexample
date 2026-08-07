#pragma once

#include <chrono>
#include <cstddef>
#include <stdexcept>
#include <tuple>
#include <utility>
#include <vector>

#include <servicelib/runtime/context.hpp>
#include <model/include/example/model/types/order_item.hpp>
#include <orderservice/internal/types/order.hpp>


namespace example::order_service::functions {

// User-owned callable. Its operator is checked by servicelib::StreamFunction
// when the generated stream graph binds it to an operator.
struct ProcessOrderItems final {
  template <typename... Outputs>
  void operator()(servicelib::MessageContext context,
                  const example::order_service::types::Order& value,
                  Outputs&&... outputs) const {
    auto collectors = std::forward_as_tuple(outputs...);
    for (auto item : value.items) {
      item.order_id = value.id;
      std::get<0>(collectors).out(context, std::move(item));
    }
  }
};

}  // namespace example::order_service::functions
