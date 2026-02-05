{ config, lib, pkgs, ... }:

{
  imports = [
    ../families/sc7280-mainline
  ];

  mobile.device.name = "fairphone-fp5";
  mobile.device.identity = {
    name = "Fairphone 5";
    manufacturer = "Fairphone";
  };
  mobile.device.supportLevel = "supported";

  mobile.hardware = {
    ram = 1024 * 8;
    screen = {
      width = 1080; height = 2400;
    };
  };

  mobile.device.firmware = pkgs.callPackage ./firmware {};

  mobile.system.android = {
    device_name = "FP5";
    appendDTB = [
      "dtbs/qcom/qcm6490-fairphone-fp5.dtb"
    ];
  };

  mobile.boot.stage-1.kernel.modules = [
    "fsa4480"                    # USB-C audio switch
    "goodix_berlin_core"         # Touchscreen core driver
    "goodix_berlin_spi"          # Touchscreen SPI interface
    "msm"                        # MSM DRM display driver
    "panel-raydium-rm692e5"      # Display panel driver
    "ptn36502"                   # USB-C redriver
    "spi-geni-qcom"              # Qualcomm SPI controller
  ];

  mobile.quirks.qualcomm.sc7280-modem.enable = true;
}
