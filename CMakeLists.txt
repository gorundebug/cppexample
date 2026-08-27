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
option(SERVICEGEN_ASAN "Enable AddressSanitizer" OFF)
option(SERVICEGEN_UBSAN "Enable UndefinedBehaviorSanitizer" OFF)
option(SERVICEGEN_TSAN "Enable ThreadSanitizer" OFF)
if(SERVICEGEN_TSAN AND (SERVICEGEN_ASAN OR SERVICEGEN_UBSAN))
  message(FATAL_ERROR "TSan cannot be combined with ASan or UBSan")
endif()
if(SERVICEGEN_ASAN)
  add_compile_options(-fsanitize=address -fno-omit-frame-pointer)
  add_link_options(-fsanitize=address -static-libasan)
endif()
if(SERVICEGEN_UBSAN)
  add_compile_options(-fsanitize=undefined -fno-omit-frame-pointer)
  add_link_options(-fsanitize=undefined)
endif()
if(SERVICEGEN_TSAN)
  add_compile_options(-fsanitize=thread -fno-omit-frame-pointer)
  add_link_options(-fsanitize=thread)
endif()
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
    "v0.2.22" CACHE STRING
    "Pinned cppservicelib revision")
set(USERVER_REPOSITORY
    "https://github.com/userver-framework/userver.git" CACHE STRING
    "Standalone userver repository")
set(USERVER_REVISION
    "c9f77729c0edce7e423def2d4a4450aa7fc9d259" CACHE STRING
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
  set(USERVER_CONAN ON CACHE BOOL "" FORCE)
  set(USERVER_INSTALL OFF CACHE BOOL "" FORCE)
  set(USERVER_DOWNLOAD_PACKAGES OFF CACHE BOOL "" FORCE)
  set(USERVER_FEATURE_GRPC ON CACHE BOOL "" FORCE)
  set(USERVER_FORCE_DOWNLOAD_GRPC OFF CACHE BOOL "" FORCE)
  set(USERVER_FORCE_DOWNLOAD_PROTOBUF OFF CACHE BOOL "" FORCE)
  set(USERVER_FEATURE_OTLP ON CACHE BOOL "" FORCE)
  set(USERVER_FEATURE_KAFKA ON CACHE BOOL "" FORCE)

  set(USERVER_FEATURE_CHAOTIC_EXPERIMENTAL ON CACHE BOOL "" FORCE)
  add_subdirectory(
      "${USERVER_SOURCE_DIR}"
      "${CMAKE_BINARY_DIR}/_deps/userver-build"
      EXCLUDE_FROM_ALL)
  userver_setup_environment()
  list(APPEND CMAKE_MODULE_PATH "${USERVER_SOURCE_DIR}/cmake")
else()
  find_package(userver QUIET COMPONENTS core grpc kafka otlp)
endif()

find_package(RdKafka CONFIG REQUIRED)


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