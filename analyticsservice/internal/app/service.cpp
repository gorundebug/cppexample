#include "analyticsservice/internal/app/service.hpp"
#include "analyticsservice/internal/functions/substreamanalytics/invoke_analytics_substream.hpp"

#include <memory>
#include <userver/utils/async.hpp>

namespace example::analytics_service::app {

void Service::customMakersInit(servicelib::Context context) {
  (void)context;
  makers_.invoke_analytics_substream = [substream =
      getAnalyzeAnalyticsSubstreamSubStream()](
      servicelib::Context, servicelib::IServiceEnvironment&) {
    return userver::utils::Async(
        "make-invoke-analytics-substream",
        [substream] {
          return std::make_unique<functions::InvokeAnalyticsSubstream>(substream);
        });
  };
}

void Service::customFunctionsInit(servicelib::Context context) {
  (void)context;
  // Add only explicit post-construction customization here.
}
void Service::serviceInit() {}
void Service::serviceStarted() {}
void Service::serviceStopping() noexcept {}

}  // namespace example::analytics_service::app
