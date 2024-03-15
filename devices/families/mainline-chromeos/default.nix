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

      "tpm"
      "tpm_tis_core"
      "tpm_tis_spi"
      "tcg_tis_i2c_cr50"
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

      TCG_TPM = module;
      TCG_TIS_CORE = module;
      TCG_TIS_SPI = module;
      TCG_TIS_SPI_CR50 = yes;
      TCG_TIS_I2C_CR50 = module;
    })
  ];
}
