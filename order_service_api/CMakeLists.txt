cmake_minimum_required(VERSION 3.24)
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
  project(example_order_service_api LANGUAGES CXX)
  include(CTest)
  set(CMAKE_CXX_STANDARD 20)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
  set(CMAKE_CXX_EXTENSIONS OFF)

  set(USERVER_SOURCE_DIR "" CACHE PATH "Path to a userver source checkout")
  option(FETCH_CPP_DEPENDENCIES
         "Fetch missing pinned C++ dependencies" ON)
  if(NOT USERVER_SOURCE_DIR AND FETCH_CPP_DEPENDENCIES)
    include(FetchContent)
    set(USERVER_FEATURE_CHAOTIC_EXPERIMENTAL ON CACHE BOOL "" FORCE)
    FetchContent_Declare(servicegen_userver
        GIT_REPOSITORY "https://github.com/userver-framework/userver.git"
        GIT_TAG "c9f77729c0edce7e423def2d4a4450aa7fc9d259"
        GIT_SHALLOW FALSE)
    FetchContent_MakeAvailable(servicegen_userver)
    set(USERVER_SOURCE_DIR "${servicegen_userver_SOURCE_DIR}")
  elseif(USERVER_SOURCE_DIR)
    set(USERVER_FEATURE_CHAOTIC_EXPERIMENTAL ON CACHE BOOL "" FORCE)
    add_subdirectory("${USERVER_SOURCE_DIR}"
        "${CMAKE_BINARY_DIR}/_deps/userver-build" EXCLUDE_FROM_ALL)
  endif()
  if(USERVER_SOURCE_DIR)
    userver_setup_environment()
    list(APPEND CMAKE_MODULE_PATH "${USERVER_SOURCE_DIR}/cmake")
  endif()
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