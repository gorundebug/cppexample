cmake_minimum_required(VERSION 3.24)
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
  project(example_inventory_service_api LANGUAGES CXX)
  include(CTest)
  set(CMAKE_CXX_STANDARD 20)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
  set(CMAKE_CXX_EXTENSIONS OFF)

  find_package(userver CONFIG REQUIRED COMPONENTS grpc)
endif()

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