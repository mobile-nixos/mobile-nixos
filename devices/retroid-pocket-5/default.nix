{
  config,
  lib,
  pkgs,
  ...
}:
let
  qcom-video-firmware = pkgs.runCommand "potter-firmware" { } ''
    dir=$out/lib/firmware/qcom
    mkdir -p $dir
    cp  ${pkgs.linux-firmware}/lib/firmware/qcom/a530* $dir
  '';
in
{

  mobile.device.name = "retroid-pocket-5";
  mobile.device.identity = {
    name = "Retroid Pocket 5";
    manufacturer = "Moorechip";
  };
  mobile.device.supportLevel = "best-effort";

  mobile.hardware = {
    soc = "qualcomm-sm8250";
    ram = 1024 * 8;
    screen = {
      width = 1920;
      height = 1080;
    };
  };

  boot.kernelParams = [
    "clk_ignore_unused"
    "pd_ignore_unused"
    "arm64.nopauth"
    "efi=noruntime"
    "console=ttyMSM0,115200n8"
    "fbcon=rotate:3"
  ];

  mobile.boot.stage-1.firmware = [
    qcom-video-firmware
  ];


  mobile.system.type = "u-boot";

  mobile.boot.stage-1.kernel = {
    package = pkgs.callPackage ./kernel { };
    modular = true;
    modules = [
      "panel-ddic-ch13726a"
      "qcom_spmi_haptics"
      "qcom_glink_smem"
      "qcom_smd"
      "qcom_common"
      "rpmhpd"
      "qcom_rpmh"
      "cmd-db"
      # These are modules because postmarketos builds them as
      # modules.  Excepting that you only need one of the two
      # panel modules (hardware-dependent) it might make more
      # sense to build them monolithically. Unless you want to
      # run your phone headlessly ...
      # "rmi_i2c" # touchscreen driver
      # "qcom-pon" # power and volume down keys
      # "panel-boe-bs052fhm-a00-6c01"
      # "panel-tianma-tl052vdxp02"
      # "msm" # DRM module
    ];
  };

  # boot.kernelModules = [ "panel-ddic-ch13726a" ];
  # boot.initrd.availableKernelModules = [
  #   "panel-ddic-ch13726a"
  #   "qcom_spmi_haptics"
  #   "qcom_glink_smem"
  #   "qcom_smd"
  #   "qcom_common"
  #   "rpmhpd"
  #   "qcom_rpmh"
  #   "cmd-db"
  # ];

  mobile.device.firmware = pkgs.armbian-firmware;

}
