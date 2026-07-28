add_executable(example_inventory_service
    cmd/service/main.cpp
    internal/app/service.generated.cpp
    internal/app/grpc_service.generated.cpp
    internal/app/service.cpp
    internal/functions/get_inventory_item_data.cpp
)

target_compile_features(example_inventory_service PRIVATE cxx_std_20)
target_include_directories(example_inventory_service PRIVATE "${PROJECT_SOURCE_DIR}")
target_link_libraries(example_inventory_service PRIVATE
    servicelib::servicelib userver-core userver-grpc
      example_inventory_service_api
)

add_executable(example_inventory_service_typed_config
    config/config.generated.cpp)
target_compile_features(example_inventory_service_typed_config PRIVATE cxx_std_20)
target_include_directories(example_inventory_service_typed_config
    PRIVATE "${PROJECT_SOURCE_DIR}")
target_link_libraries(example_inventory_service_typed_config
    PRIVATE servicelib::servicelib userver-core)
add_test(NAME example_inventory_service_typed_config
    COMMAND example_inventory_service_typed_config)

add_executable(example_inventory_service_unit_tests
    internal/functions/get_inventory_item_data_test.cpp
    internal/functions/process_order_item_test.cpp
)
target_compile_features(example_inventory_service_unit_tests PRIVATE cxx_std_20)
target_include_directories(example_inventory_service_unit_tests
    PRIVATE "${PROJECT_SOURCE_DIR}")
target_link_libraries(example_inventory_service_unit_tests PRIVATE
    servicelib::servicelib userver-core userver::utest userver-grpc
    example_inventory_service_api
)
add_google_tests(example_inventory_service_unit_tests)
