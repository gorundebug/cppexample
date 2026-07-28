add_library(example_model INTERFACE)
set(_servicegen_include_root
    "${CMAKE_CURRENT_BINARY_DIR}/servicegen-include")
file(MAKE_DIRECTORY "${_servicegen_include_root}")
if(NOT EXISTS "${_servicegen_include_root}/model")
  file(CREATE_LINK "${CMAKE_CURRENT_SOURCE_DIR}"
      "${_servicegen_include_root}/model"
      SYMBOLIC COPY_ON_ERROR)
endif()
target_include_directories(example_model INTERFACE
    "${_servicegen_include_root}")