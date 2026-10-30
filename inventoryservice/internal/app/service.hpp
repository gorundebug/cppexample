#pragma once

#include "inventoryservice/internal/app/service.generated.hpp"

namespace example::inventory_service::app {

// User-owned extension point. The generator never overwrites this file.
class Service final : public ServiceGenerated {
 public:
  using ServiceGenerated::ServiceGenerated;
  ~Service() override = default;

 protected:
  void customMakersInit(servicelib::Context context) override;
  void customFunctionsInit(servicelib::Context context) override;
  void serviceInit(servicelib::Context context) override;
  void serviceStarted(servicelib::Context context) override;
  void serviceStopping(servicelib::Context context) noexcept override;
};

}  // namespace example::inventory_service::app
