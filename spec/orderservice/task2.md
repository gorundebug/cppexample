# Task 2/6: `MapToOrderState`

> Rules: [`spec/rules.md`](../rules.md)

| Field | Value |
|-------|-------|
| Language | `C++` |
| Kind | `map` |
| File | `orderservice/internal/functions/map_to_order_state.hpp` |
| Test | `orderservice/internal/functions/map_to_order_state_test.cpp` |
| Service | `Order Service` |


## Behaviour

Convert an Order that reached the soft deadline into an OrderState.
Set OrderID from Order.ID; set Status to TIMED_OUT; leave ConfirmedItems nil.





## Stream types
- Input: `Order` — `orderservice/internal/types/order.hpp`
- Output: `OrderState` — `orderservice/internal/types/order_state.hpp`

## Checklist

- [ ] Read [`spec/rules.md`](../rules.md), especially the `C++` section
- [ ] Open `orderservice/internal/functions/map_to_order_state.hpp` and preserve its generated contract
- [ ] Inspect input type `Order` in `orderservice/internal/types/order.hpp`
- [ ] Inspect output type `OrderState` in `orderservice/internal/types/order_state.hpp`
- [ ] Implement the C++ function object without retaining borrowed payload/context references
- [ ] Run `./scripts/test.sh`
- [ ] Implement meaningful assertions in `orderservice/internal/functions/map_to_order_state_test.cpp`
- [ ] Re-read this checklist
- [ ] Append to `spec/progress.md`: `- [x] orderservice/task2.md — MapToOrderState — C++ — done`