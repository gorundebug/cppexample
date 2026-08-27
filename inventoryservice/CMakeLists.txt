cmake_minimum_required(VERSION 3.24)

# This file is both a standalone service project and a workspace subdirectory.
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
  project(example_inventory_service LANGUAGES CXX)

  set(FETCHCONTENT_UPDATES_DISCONNECTED ON CACHE BOOL "" FORCE)

  include(CTest)
  set(CMAKE_CXX_STANDARD 20)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
  set(CMAKE_CXX_EXTENSIONS OFF)

  option(USE_CCACHE "Use ccache when it is available" ON)
  option(ENABLE_OTLP_TRACING
         "Register userver OTLP tracing components" OFF)
  option(ENABLE_ASAN "Enable AddressSanitizer" OFF)
  option(ENABLE_UBSAN "Enable UndefinedBehaviorSanitizer" OFF)
  option(ENABLE_TSAN "Enable ThreadSanitizer" OFF)
  if(ENABLE_TSAN AND (ENABLE_ASAN OR ENABLE_UBSAN))
    message(FATAL_ERROR "TSan cannot be combined with ASan or UBSan")
  endif()
  if(ENABLE_ASAN)
    add_compile_options(-fsanitize=address -fno-omit-frame-pointer)
    add_link_options(-fsanitize=address -static-libasan)
  endif()
  if(ENABLE_UBSAN)
    add_compile_options(-fsanitize=undefined -fno-omit-frame-pointer)
    add_link_options(-fsanitize=undefined)
  endif()
  if(ENABLE_TSAN)
    add_compile_options(-fsanitize=thread -fno-omit-frame-pointer)
    add_link_options(-fsanitize=thread)
  endif()
  if(USE_CCACHE AND NOT CMAKE_CXX_COMPILER_LAUNCHER)
    find_program(CCACHE_PROGRAM ccache)
    if(CCACHE_PROGRAM)
      set(CMAKE_CXX_COMPILER_LAUNCHER "${CCACHE_PROGRAM}")
      message(STATUS "C++ compiler cache: ${CCACHE_PROGRAM}")
    endif()
  endif()

  set(SERVICELIB_SOURCE_DIR "" CACHE PATH
      "Path to a servicelib source checkout")
  set(USERVER_SOURCE_DIR "" CACHE PATH
      "Path to a userver source checkout")
  set(_servicegen_modules_root_default "${CMAKE_CURRENT_SOURCE_DIR}/modules")
  set(MODULES_ROOT "${_servicegen_modules_root_default}" CACHE PATH
      "Path containing local generated contract modules")
  option(FETCH_CPP_DEPENDENCIES
         "Fetch missing pinned servicelib, userver, and contract modules" ON)
  set(SERVICELIB_REPOSITORY "https://github.com/gorundebug/cppservicelib.git" CACHE STRING
      "Standalone cppservicelib repository")
  set(SERVICELIB_REVISION "v0.2.24" CACHE STRING
      "Pinned cppservicelib revision")
  set(USERVER_REPOSITORY "https://github.com/userver-framework/userver.git" CACHE STRING
      "Standalone userver repository")
  set(USERVER_REVISION "c9f77729c0edce7e423def2d4a4450aa7fc9d259" CACHE STRING
      "Pinned userver revision")
  if(FETCH_CPP_DEPENDENCIES)
    include(FetchContent)
    if(NOT USERVER_SOURCE_DIR)
      if(DEFINED ENV{DEPENDENCY_GITHUB_RAW_URL} AND
         NOT "$ENV{DEPENDENCY_GITHUB_RAW_URL}" STREQUAL "" AND
         USERVER_REPOSITORY MATCHES "^https://github.com/")
        string(REGEX REPLACE "^https://github.com/" ""
            _servicegen_userver_path "${USERVER_REPOSITORY}")
        string(REGEX REPLACE "\\.git$" ""
            _servicegen_userver_path "${_servicegen_userver_path}")
        FetchContent_Declare(servicegen_userver
            URL "$ENV{DEPENDENCY_GITHUB_RAW_URL}/${_servicegen_userver_path}/archive/${USERVER_REVISION}.tar.gz"
            DOWNLOAD_EXTRACT_TIMESTAMP TRUE)
      else()
        FetchContent_Declare(servicegen_userver
            GIT_REPOSITORY "${USERVER_REPOSITORY}"
            GIT_TAG "${USERVER_REVISION}"
            GIT_SHALLOW FALSE)
      endif()
      FetchContent_GetProperties(servicegen_userver)
      if(NOT servicegen_userver_POPULATED)
        FetchContent_Populate(servicegen_userver)
      endif()
      set(USERVER_SOURCE_DIR "${servicegen_userver_SOURCE_DIR}")
    endif()
    if(NOT SERVICELIB_SOURCE_DIR)
      if(DEFINED ENV{DEPENDENCY_GITHUB_RAW_URL} AND
         NOT "$ENV{DEPENDENCY_GITHUB_RAW_URL}" STREQUAL "" AND
         SERVICELIB_REPOSITORY MATCHES "^https://github.com/")
        string(REGEX REPLACE "^https://github.com/" ""
            _servicegen_servicelib_path "${SERVICELIB_REPOSITORY}")
        string(REGEX REPLACE "\\.git$" ""
            _servicegen_servicelib_path "${_servicegen_servicelib_path}")
        FetchContent_Declare(servicegen_servicelib
            URL "$ENV{DEPENDENCY_GITHUB_RAW_URL}/${_servicegen_servicelib_path}/archive/${SERVICELIB_REVISION}.tar.gz"
            DOWNLOAD_EXTRACT_TIMESTAMP TRUE)
      else()
        FetchContent_Declare(servicegen_servicelib
            GIT_REPOSITORY "${SERVICELIB_REPOSITORY}"
            GIT_TAG "${SERVICELIB_REVISION}"
            GIT_SHALLOW FALSE)
      endif()
      FetchContent_GetProperties(servicegen_servicelib)
      if(NOT servicegen_servicelib_POPULATED)
        FetchContent_Populate(servicegen_servicelib)
      endif()
      set(SERVICELIB_SOURCE_DIR "${servicegen_servicelib_SOURCE_DIR}")
    endif()
  endif()

  if(USERVER_SOURCE_DIR)
    set(USERVER_CONAN ON CACHE BOOL "" FORCE)
    set(USERVER_FEATURE_GRPC ON CACHE BOOL "" FORCE)
    set(USERVER_FORCE_DOWNLOAD_GRPC OFF CACHE BOOL "" FORCE)
    set(USERVER_FORCE_DOWNLOAD_PROTOBUF OFF CACHE BOOL "" FORCE)
    if(ENABLE_OTLP_TRACING)
      set(USERVER_FEATURE_OTLP ON CACHE BOOL "" FORCE)
    endif()
    set(USERVER_FEATURE_CHAOTIC_EXPERIMENTAL ON CACHE BOOL "" FORCE)
    add_subdirectory(
        "${USERVER_SOURCE_DIR}"
        "${CMAKE_BINARY_DIR}/_deps/userver-build"
        EXCLUDE_FROM_ALL)
    userver_setup_environment()
    list(APPEND CMAKE_MODULE_PATH "${USERVER_SOURCE_DIR}/cmake")
  else()
    set(_servicegen_userver_components core grpc)
    if(ENABLE_OTLP_TRACING)
      list(APPEND _servicegen_userver_components otlp)
    endif()
    find_package(userver QUIET COMPONENTS ${_servicegen_userver_components})
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
        "userver, or enable FETCH_CPP_DEPENDENCIES.")
  endif()
  if(NOT TARGET servicelib::servicelib)
    message(FATAL_ERROR
        "Standalone service requires servicelib. Set SERVICELIB_SOURCE_DIR, "
        "install servicelib, or enable FETCH_CPP_DEPENDENCIES.")
  endif()

  if(NOT TARGET example_inventory_service_api)
    set(_servicegen_module_source "${MODULES_ROOT}/inventory_service_api")
    if(EXISTS "${_servicegen_module_source}/CMakeLists.txt")
      add_subdirectory(
          "${_servicegen_module_source}"
          "${CMAKE_BINARY_DIR}/_modules/inventory_service_api")
    elseif(FETCH_CPP_DEPENDENCIES)
      include(FetchContent)
      FetchContent_Declare(servicegen_module_inventory_service_api
          GIT_REPOSITORY "https://github.com/gorundebug/cppexample-inventory-service-api.git"
          GIT_TAG "v0.2.14"
          GIT_SHALLOW FALSE)
      FetchContent_MakeAvailable(servicegen_module_inventory_service_api)
    else()
      message(FATAL_ERROR
          "Contract module inventory_service_api was not found under "
          "MODULES_ROOT=${MODULES_ROOT}.")
    endif()
  endif()
  if(NOT TARGET example_model)
    set(_servicegen_module_source "${MODULES_ROOT}/model")
    if(EXISTS "${_servicegen_module_source}/CMakeLists.txt")
      add_subdirectory(
          "${_servicegen_module_source}"
          "${CMAKE_BINARY_DIR}/_modules/model")
    elseif(FETCH_CPP_DEPENDENCIES)
      include(FetchContent)
      FetchContent_Declare(servicegen_module_model
          GIT_REPOSITORY "https://github.com/gorundebug/cppexample-model.git"
          GIT_TAG "v0.2.14"
          GIT_SHALLOW FALSE)
      FetchContent_MakeAvailable(servicegen_module_model)
    else()
      message(FATAL_ERROR
          "Contract module model was not found under "
          "MODULES_ROOT=${MODULES_ROOT}.")
    endif()
  endif()
endif()

# Generated includes keep a stable service prefix independent of the checkout
# directory name (workspace directory, Git repository name, or FetchContent).
set(_servicegen_include_root
    "${CMAKE_CURRENT_BINARY_DIR}/servicegen-include")
file(MAKE_DIRECTORY "${_servicegen_include_root}")
if(NOT EXISTS
    "${_servicegen_include_root}/inventoryservice")
  file(CREATE_LINK "${CMAKE_CURRENT_SOURCE_DIR}"
      "${_servicegen_include_root}/inventoryservice"
      SYMBOLIC COPY_ON_ERROR)
endif()

add_executable(example_inventory_service
    cmd/service/main.cpp
    internal/app/service.generated.cpp
    internal/app/grpc_service.generated.cpp
    internal/app/service.cpp
    internal/functions/inventory_item/get_inventory_item_data.cpp
)

target_compile_features(example_inventory_service PRIVATE cxx_std_20)
target_include_directories(example_inventory_service PRIVATE
    "${_servicegen_include_root}")
target_link_libraries(example_inventory_service PRIVATE
    servicelib::servicelib userver-core userver-grpc
      example_inventory_service_api
      example_model

      example_inventory_service_api
)
if(ENABLE_OTLP_TRACING)
  target_compile_definitions(example_inventory_service
      PRIVATE ENABLE_OTLP_TRACING=1)
  target_link_libraries(example_inventory_service PRIVATE userver::otlp userver-grpc)
endif()

if(BUILD_TESTING)
add_executable(example_inventory_service_typed_config
    config/config.generated.cpp)
target_compile_features(example_inventory_service_typed_config PRIVATE cxx_std_20)
target_include_directories(example_inventory_service_typed_config PRIVATE
    "${_servicegen_include_root}")
target_link_libraries(example_inventory_service_typed_config
    PRIVATE servicelib::servicelib userver-core)
add_test(NAME example_inventory_service_typed_config
    COMMAND example_inventory_service_typed_config)

add_executable(example_inventory_service_unit_tests
    internal/functions/endpoint/process_order_item_source_test.cpp
    internal/functions/inventory_item/get_inventory_item_data_test.cpp
)
target_compile_features(example_inventory_service_unit_tests PRIVATE cxx_std_20)
target_include_directories(example_inventory_service_unit_tests PRIVATE
    "${_servicegen_include_root}")
target_link_libraries(example_inventory_service_unit_tests PRIVATE
    servicelib::servicelib userver-core userver::utest userver-grpc
    example_inventory_service_api
    example_model

    example_inventory_service_api
)
add_google_tests(example_inventory_service_unit_tests)

endif()