cmake_minimum_required(VERSION 3.24)

# This file is both a standalone service project and a workspace subdirectory.
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
  project(example_analytics_service LANGUAGES CXX)

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
  if(ENABLE_ASAN OR ENABLE_UBSAN OR ENABLE_TSAN)
    add_compile_options(-g)
  endif()
  if(ENABLE_ASAN)
    add_compile_options(-fsanitize=address -fno-omit-frame-pointer)
    add_link_options(-fsanitize=address)
    if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
      add_link_options(-static-libasan)
    endif()
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

  set(_servicelib_source_dir_default "")
  if(DEFINED ENV{SERVICELIB_SOURCE_DIR})
    set(_servicelib_source_dir_default "$ENV{SERVICELIB_SOURCE_DIR}")
  endif()
  set(SERVICELIB_SOURCE_DIR "${_servicelib_source_dir_default}" CACHE PATH
      "Path to a servicelib source checkout")
  unset(_servicelib_source_dir_default)
  set(_servicegen_modules_root_default "${CMAKE_CURRENT_SOURCE_DIR}/modules")
  set(MODULES_ROOT "${_servicegen_modules_root_default}" CACHE PATH
      "Path containing local generated contract modules")
  option(FETCH_CPP_DEPENDENCIES
         "Fetch missing pinned servicelib and contract modules" ON)
  set(SERVICELIB_REPOSITORY "https://github.com/gorundebug/cppservicelib.git" CACHE STRING
      "Standalone cppservicelib repository")
  set(SERVICELIB_REVISION "v0.2.83" CACHE STRING
      "Pinned cppservicelib revision")
  if(FETCH_CPP_DEPENDENCIES)
    include(FetchContent)
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

  set(_servicegen_userver_components core chaotic grpc kafka)
  if(ENABLE_OTLP_TRACING)
    list(APPEND _servicegen_userver_components otlp)
  endif()
  find_package(jemalloc CONFIG QUIET)
  find_package(userver CONFIG REQUIRED
      COMPONENTS ${_servicegen_userver_components})

  find_package(RdKafka CONFIG REQUIRED)

  set(SERVICELIB_ENABLE_CRON ON CACHE BOOL
      "Build the libcron data source" FORCE)

  if(SERVICELIB_SOURCE_DIR)
    add_subdirectory(
        "${SERVICELIB_SOURCE_DIR}"
        "${CMAKE_BINARY_DIR}/_deps/servicelib-build"
        EXCLUDE_FROM_ALL)
  else()
    find_package(servicelib CONFIG QUIET)
  endif()

  if(NOT TARGET userver::core)
    message(FATAL_ERROR
        "Standalone service requires the Conan userver package.")
  endif()
  if(NOT TARGET servicelib::servicelib)
    message(FATAL_ERROR
        "Standalone service requires servicelib. Set SERVICELIB_SOURCE_DIR, "
        "install servicelib, or enable FETCH_CPP_DEPENDENCIES.")
  endif()

  if(NOT TARGET example_model)
    set(_servicegen_module_source "${MODULES_ROOT}/model_cpp")
    if(EXISTS "${_servicegen_module_source}/CMakeLists.txt")
      add_subdirectory(
          "${_servicegen_module_source}"
          "${CMAKE_BINARY_DIR}/_modules/model_cpp")
    elseif(FETCH_CPP_DEPENDENCIES)
      include(FetchContent)
      FetchContent_Declare(servicegen_module_model
          GIT_REPOSITORY "https://github.com/gorundebug/cppexample.git"
          GIT_TAG "v0.2.83"
          GIT_SHALLOW FALSE)
      FetchContent_GetProperties(servicegen_module_model)
      if(NOT servicegen_module_model_POPULATED)
        FetchContent_Populate(servicegen_module_model)
      endif()
      set(_servicegen_fetched_module_source
          "${servicegen_module_model_SOURCE_DIR}/model_cpp")
      if(NOT EXISTS "${_servicegen_fetched_module_source}/CMakeLists.txt")
        set(_servicegen_fetched_module_source
            "${servicegen_module_model_SOURCE_DIR}")
      endif()
      add_subdirectory(
          "${_servicegen_fetched_module_source}"
          "${CMAKE_BINARY_DIR}/_modules/model_cpp")
    else()
      message(FATAL_ERROR
          "Contract module model_cpp was not found under "
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
    "${_servicegen_include_root}/analyticsservice")
  file(CREATE_LINK "${CMAKE_CURRENT_SOURCE_DIR}"
      "${_servicegen_include_root}/analyticsservice"
      SYMBOLIC COPY_ON_ERROR)
endif()

add_executable(example_analytics_service
    cmd/service/main.cpp
    internal/app/service.generated.cpp
    internal/app/service.cpp
    internal/functions/analytics/count_order_processed.cpp
)

target_compile_features(example_analytics_service PRIVATE cxx_std_20)
target_include_directories(example_analytics_service PRIVATE
    "${_servicegen_include_root}")
target_link_libraries(example_analytics_service PRIVATE
    servicelib::servicelib servicelib::cron userver::core userver::kafka RdKafka::rdkafka
      example_model

)
if(ENABLE_OTLP_TRACING)
  target_compile_definitions(example_analytics_service
      PRIVATE ENABLE_OTLP_TRACING=1)
  target_link_libraries(example_analytics_service PRIVATE userver::otlp userver::grpc)
endif()

if(BUILD_TESTING)
add_executable(example_analytics_service_typed_config
    config/config.generated.cpp)
target_compile_features(example_analytics_service_typed_config PRIVATE cxx_std_20)
target_include_directories(example_analytics_service_typed_config PRIVATE
    "${_servicegen_include_root}")
target_link_libraries(example_analytics_service_typed_config
    PRIVATE servicelib::servicelib userver::core)
add_test(NAME example_analytics_service_typed_config
    COMMAND example_analytics_service_typed_config)

add_executable(example_analytics_service_unit_tests
    internal/functions/analytics/count_order_processed_test.cpp
    internal/functions/cron/analytics_schedule_source_test.cpp
    internal/functions/endpoint/order_processed_endpoint_source_test.cpp
)
target_compile_features(example_analytics_service_unit_tests PRIVATE cxx_std_20)
target_include_directories(example_analytics_service_unit_tests PRIVATE
    "${_servicegen_include_root}")
target_link_libraries(example_analytics_service_unit_tests PRIVATE
    servicelib::servicelib servicelib::cron userver::core userver::utest userver::kafka RdKafka::rdkafka
    example_model

)
add_google_tests(example_analytics_service_unit_tests)

endif()