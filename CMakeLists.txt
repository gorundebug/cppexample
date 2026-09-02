cmake_minimum_required(VERSION 3.24)

project(example LANGUAGES CXX)

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
option(FETCH_CPP_DEPENDENCIES
       "Fetch a missing pinned servicelib source tree" OFF)
set(SERVICELIB_REPOSITORY
    "https://github.com/gorundebug/cppservicelib.git" CACHE STRING
    "Standalone cppservicelib repository")
set(SERVICELIB_REVISION
    "v0.2.70" CACHE STRING
    "Pinned cppservicelib revision")
if(FETCH_CPP_DEPENDENCIES)
  include(FetchContent)
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

find_package(jemalloc CONFIG QUIET)
find_package(userver CONFIG REQUIRED COMPONENTS
    core chaotic chaotic-openapi grpc kafka otlp)

find_package(RdKafka CONFIG REQUIRED)
set(SERVICELIB_ENABLE_CRON ON CACHE BOOL "" FORCE)


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
      "Generated C++ services require userver (target userver::core)")
endif()
if(NOT TARGET servicelib::servicelib)
  message(FATAL_ERROR
      "Generated C++ services require servicelib "
      "(target servicelib::servicelib)")
endif()

add_subdirectory(inventory_service_api)
add_subdirectory(model_cpp)
add_subdirectory(order_service_api)
add_subdirectory(analyticsservice)
add_subdirectory(inventoryservice)
add_subdirectory(orderservice)