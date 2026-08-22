cmake_minimum_required(VERSION 3.24)
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
  project(example_inventory_service_api LANGUAGES CXX)
  include(CTest)
  set(CMAKE_CXX_STANDARD 20)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
  set(CMAKE_CXX_EXTENSIONS OFF)

  set(USERVER_SOURCE_DIR "" CACHE PATH "Path to a userver source checkout")
  option(SERVICEGEN_FETCH_CPP_DEPENDENCIES
         "Fetch missing pinned C++ dependencies" ON)
  if(NOT USERVER_SOURCE_DIR AND SERVICEGEN_FETCH_CPP_DEPENDENCIES)
    include(FetchContent)
    set(USERVER_FEATURE_GRPC ON CACHE BOOL "" FORCE)
    set(USERVER_FEATURE_CHAOTIC_EXPERIMENTAL ON CACHE BOOL "" FORCE)
    FetchContent_Declare(servicegen_userver
        GIT_REPOSITORY "https://github.com/userver-framework/userver.git"
        GIT_TAG "c9f77729c0edce7e423def2d4a4450aa7fc9d259"
        GIT_SHALLOW FALSE)
    FetchContent_MakeAvailable(servicegen_userver)
    set(USERVER_SOURCE_DIR "${servicegen_userver_SOURCE_DIR}")
  elseif(USERVER_SOURCE_DIR)
    set(USERVER_FEATURE_GRPC ON CACHE BOOL "" FORCE)
    set(USERVER_FEATURE_CHAOTIC_EXPERIMENTAL ON CACHE BOOL "" FORCE)
    add_subdirectory("${USERVER_SOURCE_DIR}"
        "${CMAKE_BINARY_DIR}/_deps/userver-build" EXCLUDE_FROM_ALL)
  endif()
  if(USERVER_SOURCE_DIR)
    userver_setup_environment()
    list(APPEND CMAKE_MODULE_PATH "${USERVER_SOURCE_DIR}/cmake")
  endif()
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