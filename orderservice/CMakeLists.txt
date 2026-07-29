cmake_minimum_required(VERSION 3.24)

# This file is both a standalone service project and a workspace subdirectory.
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
  project(example_order_service LANGUAGES CXX)

  include(CTest)
  set(CMAKE_CXX_STANDARD 20)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
  set(CMAKE_CXX_EXTENSIONS OFF)

  set(SERVICELIB_SOURCE_DIR "" CACHE PATH
      "Path to a servicelib source checkout")
  set(USERVER_SOURCE_DIR "" CACHE PATH
      "Path to a userver source checkout")
  set(SERVICEGEN_MODULES_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/.." CACHE PATH
      "Path containing local generated contract modules")
  option(SERVICEGEN_FETCH_CPP_DEPENDENCIES
         "Fetch missing pinned servicelib, userver, and contract modules" ON)
  set(SERVICELIB_REPOSITORY "https://github.com/gorundebug/cppservicelib.git" CACHE STRING
      "Standalone cppservicelib repository")
  set(SERVICELIB_REVISION "v3.0.1" CACHE STRING
      "Pinned cppservicelib revision")
  set(USERVER_REPOSITORY "https://github.com/userver-framework/userver.git" CACHE STRING
      "Standalone userver repository")
  set(USERVER_REVISION "c9f77729c0edce7e423def2d4a4450aa7fc9d259" CACHE STRING
      "Pinned userver revision")

  if(SERVICEGEN_FETCH_CPP_DEPENDENCIES)
    include(FetchContent)
    if(NOT USERVER_SOURCE_DIR)
      FetchContent_Declare(servicegen_userver
          GIT_REPOSITORY "${USERVER_REPOSITORY}"
          GIT_TAG "${USERVER_REVISION}"
          GIT_SHALLOW FALSE)
      FetchContent_GetProperties(servicegen_userver)
      if(NOT servicegen_userver_POPULATED)
        FetchContent_Populate(servicegen_userver)
      endif()
      set(USERVER_SOURCE_DIR "${servicegen_userver_SOURCE_DIR}")
    endif()
    if(NOT SERVICELIB_SOURCE_DIR)
      FetchContent_Declare(servicegen_servicelib
          GIT_REPOSITORY "${SERVICELIB_REPOSITORY}"
          GIT_TAG "${SERVICELIB_REVISION}"
          GIT_SHALLOW FALSE)
      FetchContent_GetProperties(servicegen_servicelib)
      if(NOT servicegen_servicelib_POPULATED)
        FetchContent_Populate(servicegen_servicelib)
      endif()
      set(SERVICELIB_SOURCE_DIR "${servicegen_servicelib_SOURCE_DIR}")
    endif()
  endif()

  if(USERVER_SOURCE_DIR)
    set(USERVER_FEATURE_GRPC ON CACHE BOOL "" FORCE)
    set(USERVER_FEATURE_CHAOTIC_EXPERIMENTAL ON CACHE BOOL "" FORCE)
    add_subdirectory(
        "${USERVER_SOURCE_DIR}"
        "${CMAKE_BINARY_DIR}/_deps/userver-build"
        EXCLUDE_FROM_ALL)
    userver_setup_environment()
    list(APPEND CMAKE_MODULE_PATH "${USERVER_SOURCE_DIR}/cmake")
  else()
    find_package(userver QUIET COMPONENTS core grpc)
  endif()

  if(SERVICELIB_SOURCE_DIR)
    add_subdirectory(
        "${SERVICELIB_SOURCE_DIR}"
        "${CMAKE_BINARY_DIR}/_deps/servicelib-build"
        EXCLUDE_FROM_ALL)
  else()
    find_package(servicelib CONFIG QUIET)
  endif()

  if(NOT TARGET userver-core)
    message(FATAL_ERROR
        "Standalone service requires userver. Set USERVER_SOURCE_DIR, install "
        "userver, or enable SERVICEGEN_FETCH_CPP_DEPENDENCIES.")
  endif()
  if(NOT TARGET servicelib::servicelib)
    message(FATAL_ERROR
        "Standalone service requires servicelib. Set SERVICELIB_SOURCE_DIR, "
        "install servicelib, or enable SERVICEGEN_FETCH_CPP_DEPENDENCIES.")
  endif()

  if(NOT TARGET example_inventory_service_api)
    set(_servicegen_module_source "${SERVICEGEN_MODULES_ROOT}/inventory_service_api")
    if(EXISTS "${_servicegen_module_source}/CMakeLists.txt")
      add_subdirectory(
          "${_servicegen_module_source}"
          "${CMAKE_BINARY_DIR}/_modules/inventory_service_api")
    elseif(SERVICEGEN_FETCH_CPP_DEPENDENCIES)
      include(FetchContent)
      FetchContent_Declare(servicegen_module_inventory_service_api
          GIT_REPOSITORY "https://github.com/gorundebug/cppexample-inventory-service-api.git"
          GIT_TAG "v0.0.1"
          GIT_SHALLOW FALSE)
      FetchContent_MakeAvailable(servicegen_module_inventory_service_api)
    else()
      message(FATAL_ERROR
          "Contract module inventory_service_api was not found under "
          "SERVICEGEN_MODULES_ROOT=${SERVICEGEN_MODULES_ROOT}.")
    endif()
  endif()
  if(NOT TARGET example_model)
    set(_servicegen_module_source "${SERVICEGEN_MODULES_ROOT}/model")
    if(EXISTS "${_servicegen_module_source}/CMakeLists.txt")
      add_subdirectory(
          "${_servicegen_module_source}"
          "${CMAKE_BINARY_DIR}/_modules/model")
    elseif(SERVICEGEN_FETCH_CPP_DEPENDENCIES)
      include(FetchContent)
      FetchContent_Declare(servicegen_module_model
          GIT_REPOSITORY "https://github.com/gorundebug/cppexample-model.git"
          GIT_TAG "v0.0.1"
          GIT_SHALLOW FALSE)
      FetchContent_MakeAvailable(servicegen_module_model)
    else()
      message(FATAL_ERROR
          "Contract module model was not found under "
          "SERVICEGEN_MODULES_ROOT=${SERVICEGEN_MODULES_ROOT}.")
    endif()
  endif()
  if(NOT TARGET example_order_service_api)
    set(_servicegen_module_source "${SERVICEGEN_MODULES_ROOT}/order_service_api")
    if(EXISTS "${_servicegen_module_source}/CMakeLists.txt")
      add_subdirectory(
          "${_servicegen_module_source}"
          "${CMAKE_BINARY_DIR}/_modules/order_service_api")
    elseif(SERVICEGEN_FETCH_CPP_DEPENDENCIES)
      include(FetchContent)
      FetchContent_Declare(servicegen_module_order_service_api
          GIT_REPOSITORY "https://github.com/gorundebug/cppexample-order-service-api.git"
          GIT_TAG "v0.0.1"
          GIT_SHALLOW FALSE)
      FetchContent_MakeAvailable(servicegen_module_order_service_api)
    else()
      message(FATAL_ERROR
          "Contract module order_service_api was not found under "
          "SERVICEGEN_MODULES_ROOT=${SERVICEGEN_MODULES_ROOT}.")
    endif()
  endif()
endif()

# Generated includes keep a stable service prefix independent of the checkout
# directory name (workspace directory, Git repository name, or FetchContent).
set(_servicegen_include_root
    "${CMAKE_CURRENT_BINARY_DIR}/servicegen-include")
file(MAKE_DIRECTORY "${_servicegen_include_root}")
if(NOT EXISTS
    "${_servicegen_include_root}/orderservice")
  file(CREATE_LINK "${CMAKE_CURRENT_SOURCE_DIR}"
      "${_servicegen_include_root}/orderservice"
      SYMBOLIC COPY_ON_ERROR)
endif()

add_executable(example_order_service
    cmd/service/main.cpp
    internal/app/service.generated.cpp
    internal/app/service.cpp
    internal/functions/map_order_item_result_to_order_state.cpp
    internal/functions/map_to_order_state.cpp
    internal/functions/process_order_items.cpp
    internal/functions/soft_deadline.cpp
)

target_compile_features(example_order_service PRIVATE cxx_std_20)
target_include_directories(example_order_service PRIVATE
    "${_servicegen_include_root}")
target_link_libraries(example_order_service PRIVATE
    servicelib::servicelib userver-core userver-grpc
      example_inventory_service_api
      example_model
      example_order_service_api

      example_inventory_service_api
      example_order_service_api
)

add_executable(example_order_service_typed_config
    config/config.generated.cpp)
target_compile_features(example_order_service_typed_config PRIVATE cxx_std_20)
target_include_directories(example_order_service_typed_config PRIVATE
    "${_servicegen_include_root}")
target_link_libraries(example_order_service_typed_config
    PRIVATE servicelib::servicelib userver-core)
add_test(NAME example_order_service_typed_config
    COMMAND example_order_service_typed_config)

add_executable(example_order_service_unit_tests
    internal/functions/map_order_item_result_to_order_state_test.cpp
    internal/functions/map_to_order_state_test.cpp
    internal/functions/process_order_item_test.cpp
    internal/functions/process_order_items_test.cpp
    internal/functions/process_order_test.cpp
    internal/functions/soft_deadline_test.cpp
)
target_compile_features(example_order_service_unit_tests PRIVATE cxx_std_20)
target_include_directories(example_order_service_unit_tests PRIVATE
    "${_servicegen_include_root}")
target_link_libraries(example_order_service_unit_tests PRIVATE
    servicelib::servicelib userver-core userver::utest userver-grpc
    example_inventory_service_api
    example_model
    example_order_service_api

    example_inventory_service_api
    example_order_service_api
)
add_google_tests(example_order_service_unit_tests)
