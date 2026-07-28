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
`graph/example.yaml`.
