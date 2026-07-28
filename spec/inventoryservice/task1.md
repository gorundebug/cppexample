# Task 1/2: `GetInventoryItemData`

> Rules: [`spec/rules.md`](../rules.md)

| Field | Value |
|-------|-------|
| Language | `C++` |
| Kind | `process` |
| File | `inventoryservice/internal/functions/get_inventory_item_data.hpp` |
| Test | `inventoryservice/internal/functions/get_inventory_item_data_test.cpp` |
| Service | `Inventory Service` |


## Behaviour

Look up the inventory record by OrderItem.SKU; retrieve current stock and UnitPrice from the record.
Always copy OrderID, ItemID, SKU, RequestedQty (=OrderItem.Quantity), UnitPrice into the result.
If stock >= OrderItem.Quantity: reserve the stock atomically and emit
OrderItemResult{OrderID, ItemID, SKU, RequestedQty, UnitPrice, Reserved: true, Status: CONFIRMED, AvailableQty: OrderItem.Quantity} via out.
If stock is insufficient: emit
OrderItemResult{OrderID, ItemID, SKU, RequestedQty, UnitPrice, Reserved: false, Status: OUT_OF_STOCK, AvailableQty: actual available} via rout.





## Stream types
- Input: `OrderItem` — `model/include/example/model/types/order_item.hpp`
- Output: `OrderItemResult` — `model/include/example/model/types/order_item_result.hpp`

## Checklist

- [ ] Read [`spec/rules.md`](../rules.md), especially the `C++` section
- [ ] Open `inventoryservice/internal/functions/get_inventory_item_data.hpp` and preserve its generated contract
- [ ] Inspect input type `OrderItem` in `model/include/example/model/types/order_item.hpp`
- [ ] Inspect output type `OrderItemResult` in `model/include/example/model/types/order_item_result.hpp`
- [ ] Implement the C++ function object without retaining borrowed payload/context references
- [ ] Run `./scripts/test.generated.sh`
- [ ] Implement meaningful assertions in `inventoryservice/internal/functions/get_inventory_item_data_test.cpp`
- [ ] Re-read this checklist
- [ ] Append to `spec/progress.md`: `- [x] inventoryservice/task1.md — GetInventoryItemData — C++ — done`