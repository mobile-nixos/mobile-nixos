{ config, lib, pkgs, ... }:

{
  mobile.device.name = "asus-flo";
  mobile.device.info = {
    # TODO : make kernel part of options.
    kernel = pkgs.callPackage ./kernel { kernelPatches = pkgs.defaultKernelPatches; };
    name = "Nexus 7 2013 Wifi";
    manufacturer = "Asus";
    dtb = "";
    flash_offset_base = "0x80200000";
    kernel_cmdline = "xxxxxxxxxxxxxxxxxxxxxxxxxxconsole=ttyMSM0,115200,n8 user_debug=31 msm_rtb.filter=0x3F ehci-hcd.park=3 vmalloc=340M";
    flash_offset_kernel = "0x00008000";
    flash_offset_ramdisk = "0x02000000";
    flash_offset_second = "0x00f00000";
    flash_offset_tags = "0x00000100";
    flash_pagesize = "2048";
  };
  mobile.hardware = {
    soc = "qualcomm-apq8064-1aa";
    ram = 1024 * 2;
    screen = {
      width = 1200; height = 1920;
    };
  };

  mobile.system.type = "android";
}
