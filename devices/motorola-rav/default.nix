{ pkgs, config, ... }:

{
  mobile.device.name = "motorola-rav";
  mobile.device.identity = {
    name = "moto g(8)";
    manufacturer = "motorola";
  };

  mobile.hardware = {
    soc = "qualcomm-sm6125";
    ram = 1024 * 3;
    screen = {
      width = 720; height = 1560;
    };
  };

  mobile.boot.stage-1 = {
    kernel.package = pkgs.callPackage ./kernel { };
  };

  mobile.device.firmware = pkgs.callPackage ./firmware {};

  mobile.boot.stage-1.firmware = [
    config.mobile.device.firmware
  ];

  # While the actual device is `rav`, TWRP is built for a common family.
  # TODO: allow a list of compatible device names?
  mobile.system.android.device_name = "sofiar";
  mobile.system.android = {
    # This device has an A/B partition scheme.
    ab_partitions = true;

    # In addition to boot_a/boot_b, it has recovery_a/recovery_b
    # ¯\_(ツ)_/¯
    has_recovery_partition = true;

    # Uses dynamic partitions
    # TODO:
    # dynamic_partitions = true;

    bootimg.flash = {
      offset_base = "0x00000000";
      offset_kernel = "0x00008000";
      offset_ramdisk = "0x01000000";
      offset_second = "0x00f00000";
      offset_tags = "0x00000100";
      pagesize = "4096";
    };
  };

  boot.kernelParams = [
    # Extracted from an Android boot image
    #"console=ttyMSM0,115200,n8"
    #"androidboot.hardware=qcom"
    #"androidboot.console=ttyMSM0"
    #"androidboot.memcg=1"
    #"lpm_levels.sleep_disabled=1"
    #"video=vfb:640x400,bpp=32,memsize=3072000"
    #"msm_rtb.filter=0x237"
    #"service_locator.enable=1"
    #"swiotlb=1"
    #"earlycon=msm_geni_serial,0x4a90000"
    #"loop.max_part=7"
    #"cgroup.memory=nokmem,nosocket"
    #"androidboot.usbcontroller=4e00000.dwc3"
    #"printk.devkmsg=on"
    #"androidboot.hab.csv=1"
    #"androidboot.hab.product=rav"
    #"androidboot.hab.cid=50"
    #"firmware_class.path=/vendor/firmware_mnt/image"
    #"buildvariant=user"
  ];

  mobile.system.type = "android";

  mobile.usb.mode = "gadgetfs";

  # Motorola
  mobile.usb.idVendor = "22B8";
  # (Used for fastboot)
  mobile.usb.idProduct = "2E80";

  mobile.usb.gadgetfs.functions = {
    rndis = "gsi.rndis";
    adb = "ffs.adb";
  };
}
