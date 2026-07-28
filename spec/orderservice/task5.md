# Task 5/6: `ProcessOrder`

> Rules: [`spec/rules.md`](../rules.md)

| Field | Value |
|-------|-------|
| Language | `C++` |
| Kind | `http-source` |
| File | `orderservice/internal/functions/process_order.hpp` |
| Test | `orderservice/internal/functions/process_order_test.cpp` |
| Service | `Order Service` |


## Behaviour

HTTP source handler for POST /v1/processorder.
[Handler] holds timeout time.Duration read from config property 'timeout' (milliseconds, default 5000).
[HandlerState] carries a context cancel function.
[BeginRequest] attaches context timeout via WithTimeout, stores cancel in handler state.
[ConsumeMessage] decodes JSON body; validates Items non-empty and all quantities positive (write 400 and return error on failure);
generates order ID as UUID; maps each item to OrderItem (ItemId, SKU, Quantity);
reads optional CustomerId; builds Order with CreatedAt=now;
registers result callback keyed on order ID; emits Order via sc.Collect.
[Result callback] called once per result (N inventory results + possibly one TIMED_OUT);
captures in its closure: sync.Mutex mu, accumulator []OrderItemResult, responseSent bool;
locks mu on each invocation;
if responseSent return true;
if Status==TIMED_OUT compute TotalAmount as sum of item.UnitPrice*item.RequestedQty for each accumulated item, write partial response with accumulated items, call Done(), return true;
otherwise append result.ConfirmedItems to accumulator and return false if len(accumulated) < N;
when all N collected compute status (CONFIRMED if all items in accumulator have Reserved==true, else PARTIALLY_CONFIRMED),
compute TotalAmount as sum of item.UnitPrice * item.RequestedQty for each item in accumulator,
write JSON response, call Done(), return true.
[GetMessageID] returns OrderState.OrderID.
[EndRequest] cancels context.
[Private helper] converts OrderState to ProcessOrderResponse mapping all fields including optional ConfirmedItems slice.




## External contract

| Field | Value |
|-------|-------|
| Format | `openapi` |
| Request | `handlers::order_service_api::processorder::Request` |
| Response | `handlers::order_service_api::processorder::Response` |


## Stream types
- Input: `Order` — `orderservice/internal/types/order.hpp`
- Output: `OrderState` — `orderservice/internal/types/order_state.hpp`

## Checklist

- [ ] Read [`spec/rules.md`](../rules.md), especially the `C++` section
- [ ] Open `orderservice/internal/functions/process_order.hpp` and preserve its generated contract
- [ ] Inspect input type `Order` in `orderservice/internal/types/order.hpp`
- [ ] Inspect output type `OrderState` in `orderservice/internal/types/order_state.hpp`
- [ ] Implement the C++ function object without retaining borrowed payload/context references
- [ ] Run `./scripts/test.sh`
- [ ] Implement meaningful assertions in `orderservice/internal/functions/process_order_test.cpp`
- [ ] Verify the endpoint/result lifecycle, including completion and error paths
- [ ] Re-read this checklist
- [ ] Append to `spec/progress.md`: `- [x] orderservice/task5.md — ProcessOrder — C++ — done`