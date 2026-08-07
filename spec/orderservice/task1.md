# Task 1/6: `MapOrderItemResultToOrderState`

> Rules: [`spec/rules.md`](../rules.md)

| Field | Value |
|-------|-------|
| Language | `C++` |
| Kind | `map` |
| File | `orderservice/internal/functions/map_order_item_result_to_order_state.hpp` |
| Test | `orderservice/internal/functions/map_order_item_result_to_order_state_test.cpp` |
| Service | `Order Service` |


## Behaviour

Convert a single OrderItemResult into an OrderState.
Set OrderID from result.OrderID; set Status=CONFIRMED if result.Reserved==true, otherwise PARTIALLY_CONFIRMED.
Set ConfirmedItems to a single-element slice containing result.





## Stream types
- Input: `OrderItemResult` — `model/include/example/model/types/order_item_result.hpp`
- Output: `OrderState` — `orderservice/internal/types/order_state.hpp`

## Checklist

- [ ] Read [`spec/rules.md`](../rules.md), especially the `C++` section
- [ ] Open `orderservice/internal/functions/map_order_item_result_to_order_state.hpp` and preserve its generated contract
- [ ] Inspect input type `OrderItemResult` in `model/include/example/model/types/order_item_result.hpp`
- [ ] Inspect output type `OrderState` in `orderservice/internal/types/order_state.hpp`
- [ ] Implement the C++ function object without retaining borrowed payload/context references
- [ ] Run `./scripts/test.generated.sh`
- [ ] Implement meaningful assertions in `orderservice/internal/functions/map_order_item_result_to_order_state_test.cpp`
- [ ] Re-read this checklist
- [ ] Append to `spec/progress.md`: `- [x] orderservice/task1.md — MapOrderItemResultToOrderState — C++ — done`