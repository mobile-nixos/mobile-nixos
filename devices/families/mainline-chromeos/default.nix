{ config, lib, pkgs, ... }:

{
  mobile.boot.stage-1 = {
    kernel.modular = true;
    kernel.additionalModules = [
      # Breaks udev if builtin or loaded before udev runs.
      # Using `additionalModules` means udev will load them as needed.
      "sbs-battery"
      "sbs-charger"
      "sbs-manager"
    ];
  };

  mobile.system.type = "depthcharge";

  mobile.kernel.structuredConfig = [
    (helpers: with helpers; {
      MODULES = yes;
      I2C_SMBUS = module;
      BATTERY_SBS = module;
      CHARGER_SBS = module;
      MANAGER_SBS = module;

      # CR50 TPM support
      TCG_TIS_CORE = yes;
      TCG_TIS_SPI = yes;
      TCG_TIS_SPI_CR50 = yes;
      TCG_TIS_I2C_CR50 = yes;
    })
  ];
}
