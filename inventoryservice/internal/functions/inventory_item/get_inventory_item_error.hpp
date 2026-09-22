#pragma once

#include <chrono>
#include <cstddef>
#include <memory>
#include <stdexcept>
#include <tuple>
#include <utility>
#include <vector>

#include <servicelib/runtime/context.hpp>
#include <servicelib/runtime/common.hpp>
#include <servicelib/runtime/base.hpp>
#include <servicelib/runtime/consumer.hpp>
#include <servicelib/runtime/config/stream_types.hpp>
#include <servicelib/runtime/environment/environment.hpp>
#include <userver/engine/task/task_with_result.hpp>
#include <userver/utils/async.hpp>
#include <inventoryservice/internal/types/inventory_failure.hpp>
#include <example/model/types/order_item_result.hpp>
#include "inventoryservice/internal/functions/inventory_item/get_inventory_item_data.hpp"


namespace example::inventory_service::functions {

// User-owned callable. Its operator is checked by servicelib::StreamFunction
// when the generated stream graph binds it to an operator.
struct GetInventoryItemError final {
  template <typename Output>
  void operator()(servicelib::MessageContext context,
                  servicelib::StreamBase& stream,
                  const std::exception_ptr& value,
                  Output&& out) const {
    (void)stream;
    try {
      std::rethrow_exception(value);
    } catch (const InventoryFailureError& failure) {
      const auto& item = failure.Item();
      out.out(std::move(context), example::model::types::OrderItemResult{
          item.order_id, item.item_id, item.sku, item.quantity,
          failure.AvailableQty(), false, "OUT_OF_STOCK", item.unit_price,
          failure.what()});
    } catch (const std::exception& error) {
      out.out(std::move(context), example::model::types::OrderItemResult{
          {}, {}, {}, 0, 0, false, "PROCESSING_ERROR", 0.0, error.what()});
    }
  }
};

inline userver::engine::TaskWithResult<std::unique_ptr<GetInventoryItemError>> MakeGetInventoryItemError(
    servicelib::Context context, servicelib::IServiceEnvironment& environment) {
  return userver::utils::Async(
      "make-get_inventory_item_error", [context = std::move(context), &environment]() mutable {
        (void)context;
        (void)environment;

        return std::make_unique<GetInventoryItemError>();
      });
}

}  // namespace example::inventory_service::functions
