include(UserverGrpcTargets)

set(_GENERATED_DIR "${CMAKE_BINARY_DIR}/generated/example/inventory_service_api")
file(MAKE_DIRECTORY "${_GENERATED_DIR}")

userver_add_grpc_library(example_inventory_service_api
    SOURCE_PATH "${CMAKE_CURRENT_SOURCE_DIR}"
    OUTPUT_PATH "${_GENERATED_DIR}"
    PROTOS
      proto/inventoryserviceapi/inventoryserviceapi.generated.proto
      proto/inventoryserviceapi/processorderitem/processorderitem.proto)

set(example_inventory_service_api_GENERATED_DIR "${_GENERATED_DIR}"
    CACHE INTERNAL "Generated protobuf/gRPC sources for inventory_service_api")