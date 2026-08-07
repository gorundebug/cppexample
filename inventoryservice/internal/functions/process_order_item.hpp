#pragma once

#include <exception>
#include <stdexcept>
#include <string>
#include <utility>
#include <variant>

#include <servicelib/runtime/common.hpp>
#include <model/include/example/model/types/order_item.hpp>
#include <model/include/example/model/types/order_item_result.hpp>
#include <proto/inventoryserviceapi/processorderitem/processorderitem.pb.h>


namespace example::inventory_service::functions {

// User-owned transport mapping. The generated endpoint owns request
// correlation, cancellation, metrics and graceful shutdown.
struct ProcessOrderItem final {
  using State = std::monostate;

  servicelib::BeginResult<State> beginRequest(
      servicelib::MessageContext context, auto&) const {
    return {std::move(context), {}};
  }

  void consumeMessage(
      servicelib::MessageContext context, auto& stream_context, State&,
      const processorderitem::ProcessOrderItemRequest& request, auto result_context,
      auto& sender) const {
    (void)sender;
    result_context.setResultCallback(
        request.item_id(),
        [result_context](
            servicelib::MessageContext callback_context,
            auto& callback_stream_context, State&,
            const example::model::types::OrderItemResult& result,
            auto& callback_sender) mutable {
          (void)callback_context;
          (void)callback_stream_context;
          processorderitem::ProcessOrderItemResponse response;
          response.set_available_qty(result.available_qty);
          response.set_reserved(result.reserved);
          response.set_status(result.status);
          callback_sender.send(std::move(response));
          result_context.done();
          return true;
        });

    stream_context.collect(
        std::move(context),
        example::model::types::OrderItem{
            request.order_id(),
            request.item_id(),
            request.sku(),
            request.quantity(),
            0.0,
        });
  }

  std::string getMessageId(
      servicelib::MessageContext context, auto& stream_context, State&,
      const example::model::types::OrderItemResult& result) const {
    (void)context;
    (void)stream_context;
    return result.item_id;
  }

  void eof(servicelib::MessageContext, auto&, State&) const noexcept {}

  void endRequest(servicelib::MessageContext, auto&, std::exception_ptr,
                  State&) const noexcept {}
};

}  // namespace example::inventory_service::functions
