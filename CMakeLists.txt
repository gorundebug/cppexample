cmake_minimum_required(VERSION 3.24)

project(example LANGUAGES CXX)

set(FETCHCONTENT_UPDATES_DISCONNECTED ON CACHE BOOL "" FORCE)

include(CTest)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

option(SERVICEGEN_USE_CCACHE "Use ccache when it is available" ON)
option(SERVICEGEN_ENABLE_OTLP_TRACING
       "Register userver OTLP tracing components" OFF)
if(SERVICEGEN_USE_CCACHE AND NOT CMAKE_CXX_COMPILER_LAUNCHER)
  find_program(SERVICEGEN_CCACHE_PROGRAM ccache)
  if(SERVICEGEN_CCACHE_PROGRAM)
    set(CMAKE_CXX_COMPILER_LAUNCHER "${SERVICEGEN_CCACHE_PROGRAM}")
    message(STATUS "C++ compiler cache: ${SERVICEGEN_CCACHE_PROGRAM}")
  endif()
endif()

set(SERVICELIB_SOURCE_DIR "" CACHE PATH
    "Path to a servicelib source checkout")
set(USERVER_SOURCE_DIR "" CACHE PATH
    "Path to a userver source checkout")
option(SERVICEGEN_FETCH_CPP_DEPENDENCIES
       "Fetch missing pinned servicelib and userver source trees" OFF)
set(SERVICELIB_REPOSITORY
    "https://github.com/gorundebug/cppservicelib.git" CACHE STRING
    "Standalone cppservicelib repository")
set(SERVICELIB_REVISION
    "v0.2.6" CACHE STRING
    "Pinned cppservicelib revision")
set(USERVER_REPOSITORY
    "https://github.com/userver-framework/userver.git" CACHE STRING
    "Standalone userver repository")
set(USERVER_REVISION
    "c9f77729c0edce7e423def2d4a4450aa7fc9d259" CACHE STRING
    "Pinned userver revision")
set(SERVICEGEN_RDKAFKA_REPOSITORY
    "https://github.com/confluentinc/librdkafka" CACHE STRING
    "Pinned librdkafka repository")
set(SERVICEGEN_RDKAFKA_REVISION
    "v2.8.0" CACHE STRING
    "Pinned librdkafka revision")


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
  include(FetchContent)
  if(NOT FETCHCONTENT_SOURCE_DIR_RDKAFKA)
    FetchContent_Declare(servicegen_librdkafka
        GIT_REPOSITORY "${SERVICEGEN_RDKAFKA_REPOSITORY}"
        GIT_TAG "${SERVICEGEN_RDKAFKA_REVISION}"
        GIT_SHALLOW TRUE
        GIT_PROGRESS TRUE)
    FetchContent_GetProperties(servicegen_librdkafka)
    if(NOT servicegen_librdkafka_POPULATED)
      FetchContent_Populate(servicegen_librdkafka)
    endif()
    set(FETCHCONTENT_SOURCE_DIR_RDKAFKA
        "${servicegen_librdkafka_SOURCE_DIR}" CACHE PATH
        "Pinned librdkafka source used by userver" FORCE)
  endif()
  set(USERVER_DOWNLOAD_PACKAGE_KAFKA ON CACHE BOOL "" FORCE)
  set(CMAKE_DISABLE_FIND_PACKAGE_RdKafka ON CACHE BOOL "" FORCE)
  message(STATUS
      "Using pinned librdkafka source ${SERVICEGEN_RDKAFKA_REVISION}")
endif()


set(_servicegen_cpm_directory "")
if(CPM_SOURCE_CACHE AND NOT CPM_SOURCE_CACHE STREQUAL "OFF")
  set(_servicegen_cpm_directory "${CPM_SOURCE_CACHE}/cpm")
elseif(DEFINED ENV{CPM_SOURCE_CACHE} AND
       NOT "$ENV{CPM_SOURCE_CACHE}" STREQUAL "")
  set(_servicegen_cpm_directory "$ENV{CPM_SOURCE_CACHE}/cpm")
endif()
if(_servicegen_cpm_directory)
  file(MAKE_DIRECTORY "${_servicegen_cpm_directory}")
  if(DEFINED CPM_DIRECTORY AND
     NOT CPM_DIRECTORY STREQUAL _servicegen_cpm_directory)
    get_cmake_property(_servicegen_cache_variables CACHE_VARIABLES)
    foreach(_servicegen_cache_variable IN LISTS _servicegen_cache_variables)
      if(_servicegen_cache_variable MATCHES
         "^CPM_(DIRECTORY|FILE|VERSION|PACKAGES|PACKAGE_.+)$")
        unset("${_servicegen_cache_variable}" CACHE)
      endif()
    endforeach()
  endif()
endif()

if(USERVER_SOURCE_DIR)
  set(USERVER_FEATURE_GRPC ON CACHE BOOL "" FORCE)
  set(USERVER_FORCE_DOWNLOAD_GRPC ON CACHE BOOL "" FORCE)
  set(USERVER_FORCE_DOWNLOAD_PROTOBUF ON CACHE BOOL "" FORCE)
  set(USERVER_FEATURE_OTLP ON CACHE BOOL "" FORCE)
  set(USERVER_FEATURE_KAFKA ON CACHE BOOL "" FORCE)

  set(USERVER_FEATURE_CHAOTIC_EXPERIMENTAL ON CACHE BOOL "" FORCE)
  add_subdirectory(
      "${USERVER_SOURCE_DIR}"
      "${CMAKE_BINARY_DIR}/_deps/userver-build"
      EXCLUDE_FROM_ALL)
  unset(CMAKE_DISABLE_FIND_PACKAGE_RdKafka CACHE)

  userver_setup_environment()
  list(APPEND CMAKE_MODULE_PATH "${USERVER_SOURCE_DIR}/cmake")
else()
  find_package(userver QUIET COMPONENTS core grpc kafka otlp)
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
      "Generated C++ services require userver (target userver-core)")
endif()
if(NOT TARGET servicelib::servicelib)
  message(FATAL_ERROR
      "Generated C++ services require servicelib "
      "(target servicelib::servicelib)")
endif()

add_subdirectory(inventory_service_api)
add_subdirectory(model)
add_subdirectory(order_service_api)
add_subdirectory(analyticsservice)
add_subdirectory(inventoryservice)
add_subdirectory(orderservice)