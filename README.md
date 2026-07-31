# C++ Servicegen Example

Self-contained C++/userver implementation of the generated order-processing
example. The repository contains two independent services and their model,
OpenAPI, and protobuf contract libraries.

## Services

- `inventoryservice` — gRPC inventory reservation service.
- `orderservice` — HTTP order-processing service.

## Contract libraries

- `inventory_service_api`
- `order_service_api`
- `model`

## Run with Docker

```bash
make docker-up
```

Submit an order that can be reserved from the initial inventory:

```bash
curl --fail-with-body \
  -X POST http://localhost:9091/v1/processorder \
  -H 'Content-Type: application/json' \
  -d '{
    "customer_id": "customer-1",
    "items": [
      {
        "item_id": "item-1",
        "sku": "SKU-001",
        "quantity": 2,
        "unit_price": 799.0
      }
    ]
  }'
```

The response has order status `CONFIRMED`; its item has `reserved: true` and
status `CONFIRMED`. Initial inventory is `SKU-001: 100`, `SKU-002: 50`, and
`SKU-003: 25`. Successful requests reduce that inventory until the Inventory
Service is restarted.

Run the integration scenario:

```bash
make integration-test
```

Stop the services:

```bash
make docker-down
```

Use `make help` to see all generated build, test, lint, formatting, and
observability commands.

The source architecture used to generate the project is available in
`graph/example.generated.yaml`.
