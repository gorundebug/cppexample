# Task 4/6: `SoftDeadline`

> Rules: [`spec/rules.md`](../rules.md)

| Field | Value |
|-------|-------|
| Language | `C++` |
| Kind | `delay` |
| File | `orderservice/internal/functions/soft_deadline.hpp` |
| Test | `orderservice/internal/functions/soft_deadline_test.cpp` |
| Service | `Order Service` |


## Behaviour

Cast stream.GetConfig() to *runtimecfg.DelayStreamConfig and convert cfg.Duration (int, milliseconds) to time.Duration — this is the safety margin.
If ctx has no deadline (ctx.Deadline() ok==false), return the margin directly.
Otherwise compute time.Until(deadline) minus the margin: if the result is negative return 0, otherwise return it.





## Stream types
- Input: `Order` — `orderservice/internal/types/order.hpp`
- Output: `Order` — `orderservice/internal/types/order.hpp`

## Checklist

- [ ] Read [`spec/rules.md`](../rules.md), especially the `C++` section
- [ ] Open `orderservice/internal/functions/soft_deadline.hpp` and preserve its generated contract
- [ ] Inspect input type `Order` in `orderservice/internal/types/order.hpp`
- [ ] Inspect output type `Order` in `orderservice/internal/types/order.hpp`
- [ ] Implement the C++ function object without retaining borrowed payload/context references
- [ ] Run `./scripts/test.sh`
- [ ] Implement meaningful assertions in `orderservice/internal/functions/soft_deadline_test.cpp`
- [ ] Re-read this checklist
- [ ] Append to `spec/progress.md`: `- [x] orderservice/task4.md — SoftDeadline — C++ — done`