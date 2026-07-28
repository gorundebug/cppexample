#pragma once

#include <chrono>
#include <cstddef>
#include <memory>
#include <mutex>
#include <stdexcept>
#include <tuple>
#include <unordered_map>
#include <utility>
#include <vector>

#include <servicelib/runtime/context.hpp>
#include <model/include/example/model/types/order_item.hpp>
#include <model/include/example/model/types/order_item_result.hpp>


namespace example::inventory_service::functions {

// User-owned callable. Its operator is checked by servicelib::StreamFunction
// when the generated stream graph binds it to an operator.
struct GetInventoryItemData final {
  GetInventoryItemData() : state_(std::make_shared<State>()) {
    state_->stock = {
        {"SKU-001", 100},
        {"SKU-002", 50},
        {"SKU-003", 25},
    };
  }

  template <typename Output, typename ErrorOutput>
  void operator()(servicelib::MessageContext context,
                  const example::model::types::OrderItem& value,
                  Output&& out,
                  ErrorOutput&& errors) const {
    std::int32_t available = 0;
    bool reserved = false;
    {
      std::lock_guard lock(state_->mutex);
      const auto it = state_->stock.find(value.sku);
      if (it != state_->stock.end()) {
        available = it->second;
        if (available >= value.quantity) {
          it->second -= value.quantity;
          reserved = true;
        }
      }
    }

    example::model::types::OrderItemResult result{
        value.order_id,
        value.item_id,
        value.sku,
        value.quantity,
        reserved ? value.quantity : available,
        reserved,
        reserved ? "CONFIRMED" : "OUT_OF_STOCK",
        value.unit_price,
    };
    if (reserved) {
      out.out(std::move(context), std::move(result));
    } else {
      errors.out(std::move(context), std::move(result));
    }
  }

 private:
  struct State final {
    std::mutex mutex;
    std::unordered_map<std::string, std::int32_t> stock;
  };

  std::shared_ptr<State> state_;
};

}  // namespace example::inventory_service::functions
