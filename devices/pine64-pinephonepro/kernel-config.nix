{ config, lib, pkgs, ... }:

{
  # Minimum driver hardware requirements
  mobile.kernel.structuredConfig = [
    (helpers: with helpers; {
      # eMMC
      MMC_SDHCI_OF_ARASAN = yes;

      # Display
      DRM_PANEL_HIMAX_HX8394 = yes;

      # Touch screen
      TOUCHSCREEN_GOODIX = yes;

      # General wireless
      WIRELESS = yes;

      # Bluetooth
      BT = yes;
      BT_HCIUART = yes;
      BT_HCIUART_BCM = yes;

      # Wifi
      WLAN = yes;
      WLAN_VENDOR_BROADCOM = yes;
      BRCMUTIL = yes;
      BRCMFMAC = yes;
      BRCMFMAC_SDIO = yes;
      BRCMSMAC = yes;
      BRCMDBG = yes;
      MAC80211 = yes;

      # Sensors
      STK3310 = yes; # Light sensor

      # SPI Flash
      SPI = yes;
      SPI_ROCKCHIP = yes;
      MTD = yes;
      MTD_SPI_NOR = yes;

      # Keyboard
      IP5XXX_POWER = yes;
      KEYBOARD_PINEPHONE = yes;

      # Vibrate motor
      INPUT_GPIO_VIBRA = yes;

      # Cameras
      VIDEO_ROCKCHIP_ISP1 = yes;
      PHY_ROCKCHIP_DPHY_RX0 = yes; # Front camera MIPI receiver
      ROCKCHIP_DW_MIPI_DSI = yes; # DSI1 doubles as the rear camera MIPI receiver
      VIDEO_IMX258 = yes; # Rear camera
      VIDEO_DW9714 = yes; # Rear camera focus
      VIDEO_OV8858 = yes; # Front camera
      LEDS_SGM3140 = yes; # Flash
    })
  ];
}
