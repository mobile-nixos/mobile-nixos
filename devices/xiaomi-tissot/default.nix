{ config, lib, pkgs, ... }:
let
  inherit (config.mobile.device) name;
in {
  mobile.device.name = "xiaomi-tissot";
  mobile.device.info = {
    name = "A1";
    manufacturer = "Xiaomi";
    kernel_cmdline = "androidboot.hardware=qcom msm_rtb.filter=0x237 ehci-hcd.park=3 lpm_levels.sleep_disabled=1 androidboot.bootdevice=7824900.sdhci earlycon=msm_hsl_uart,0x78af000 androidboot.selinux=permissive buildvariant=eng";
    flash_offset_base = "0x80000000";
    flash_offset_kernel = "0x00008000";
    flash_offset_second = "0x00f00000";
    flash_offset_ramdisk = "0x01000000";
    flash_offset_tags = "0x00000100";
    flash_pagesize = "2048";
    kernel = pkgs.callPackage ./kernel { kernelPatches = pkgs.defaultKernelPatches; };
    #dtb = "${kernel}/dtbs/msm8953-qrd-sku3-tissot.dtb";
  };
  mobile.hardware = {
    soc = "qualcomm-msm8953";
    ram = 1024 * 4;
    screen = {
      width = 1080; height = 1920;
    };
  };

  mobile.system.type = "android";
}
