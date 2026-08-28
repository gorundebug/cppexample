cmake_minimum_required(VERSION 3.24)
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
  project(example_order_service_api LANGUAGES CXX)
  include(CTest)
  set(CMAKE_CXX_STANDARD 20)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
  set(CMAKE_CXX_EXTENSIONS OFF)

  find_package(userver CONFIG REQUIRED COMPONENTS core chaotic)
endif()

set(_GENERATED_DIR "${CMAKE_BINARY_DIR}/generated/example/order_service_api")


userver_target_generate_openapi_handlers(
    example_order_service_api_order_service_api
    NAME order_service_api
    OUTPUT_DIR "${_GENERATED_DIR}/order_service_api"
    SCHEMAS
      "${CMAKE_CURRENT_LIST_DIR}/openapi/orderserviceapi/orderserviceapi.cpp.generated.yaml")

set_source_files_properties(
    "${CMAKE_BINARY_DIR}/generated/example/order_service_api/order_service_api/src/handlers/order_service_api/processorder/handler.cpp"
    "${CMAKE_BINARY_DIR}/generated/example/order_service_api/order_service_api/src/handlers/order_service_api/processorder/requests.cpp"
    "${CMAKE_BINARY_DIR}/generated/example/order_service_api/order_service_api/src/handlers/order_service_api/processorder/responses.cpp"
    PROPERTIES HEADER_FILE_ONLY TRUE)

add_library(example_order_service_api INTERFACE)
target_link_libraries(example_order_service_api INTERFACE
    example_order_service_api_order_service_api)

set(example_order_service_api_GENERATED_DIR "${_GENERATED_DIR}"
    CACHE INTERNAL "Generated OpenAPI sources for order_service_api")