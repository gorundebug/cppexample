#pragma once

#include <exception>
#include <stdexcept>
#include <string>
#include <utility>
#include <variant>

#include "runtime/common.hpp"
#include <model/include/example/model/types/order_item.hpp>
#include <model/include/example/model/types/order_item_result.hpp>
#include <proto/inventoryserviceapi/processorderitem/processorderitem.pb.h>


namespace example::order_service::functions {

// User-owned transport mapping. The generated endpoint owns request
// correlation, cancellation, metrics and graceful shutdown.
struct ProcessOrderItem final {
  struct State final {
    std::string order_id;
    std::string item_id;
    std::string sku;
    std::int32_t requested_qty{0};
    double unit_price{0.0};
  };

  servicelib::BeginResult<State> beginRequest(
      servicelib::MessageContext context, auto&) const {
    return {std::move(context), State{}};
  }

  void consumeMessage(
      servicelib::MessageContext context, auto& stream_context,
      State& state, const example::model::types::OrderItem& value,
      auto& sender, auto result_context) const {
    (void)context;
    (void)stream_context;
    (void)result_context;
    state.order_id = value.order_id;
    state.item_id = value.item_id;
    state.sku = value.sku;
    state.requested_qty = value.quantity;
    state.unit_price = value.unit_price;

    processorderitem::ProcessOrderItemRequest request;
    request.set_order_id(value.order_id);
    request.set_item_id(value.item_id);
    request.set_sku(value.sku);
    request.set_quantity(value.quantity);
    sender.send(std::move(request));
  }

  void handleResponse(
      servicelib::MessageContext context, auto& stream_context, State& state,
      const processorderitem::ProcessOrderItemResponse& response) const {
    stream_context.collect(
        std::move(context),
        example::model::types::OrderItemResult{
            state.order_id,
            state.item_id,
            state.sku,
            state.requested_qty,
            response.available_qty(),
            response.reserved(),
            response.status(),
            state.unit_price,
        });
  }

  void endRequest(servicelib::MessageContext, auto&, std::exception_ptr,
                  State&) const noexcept {}
};

}  // namespace example::order_service::functions
