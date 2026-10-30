#include "inventoryservice/internal/app/service.hpp"

namespace example::inventory_service::app {

void Service::customMakersInit(servicelib::Context context) {
  (void)context;
  // Add only explicit user overrides here. Generated defaults stay in the
  // generated service and may change freely when the graph is regenerated.
}

void Service::customFunctionsInit(servicelib::Context context) {
  (void)context;
  // Add only explicit post-construction customization here.
}
void Service::serviceInit(servicelib::Context) {}
void Service::serviceStarted(servicelib::Context) {}
void Service::serviceStopping(servicelib::Context) noexcept {}

}  // namespace example::inventory_service::app
