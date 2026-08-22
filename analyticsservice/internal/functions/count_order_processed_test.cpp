#include <concepts>

#include <userver/utest/utest.hpp>

#include "analyticsservice/internal/functions/count_order_processed.hpp"

namespace example::analytics_service::functions {

UTEST(CountOrderProcessed, Contract) {
  static_assert(std::default_initializable<CountOrderProcessed>);
  GTEST_SKIP() << "TODO: add behavior assertions for CountOrderProcessed";
}

}  // namespace example::analytics_service::functions