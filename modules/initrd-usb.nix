{ config, lib, pkgs, ... }:

with lib;
with import ./initrd-order.nix;

let
  cfg = config.mobile.boot.stage-1;
  device_name = device_config.name;
  device_config = config.mobile.device;
  system_type = config.mobile.system.type;

  rndis_f_name = if device_config.info ? usb && device_config.info.usb ? rndis_f_name
    then device_config.info.usb.rndis_f_name
    else "rndis"
  ;
in
{
  # FIXME Generic USB gadget support to come.
  options.mobile.boot.stage-1.usb = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Enables USB features.
        For now, only Android-based devices are supported.
      '';
    };
    features = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        `android_usb` features to enable.
      '';
    };
    adbd = mkOption {
      type = types.bool;
      default = system_type == "android";
      description = ''
        Enables adbd on the device.
      '';
    };
  };

  config.mobile.boot.stage-1 = lib.mkIf cfg.usb.enable {
    usb.features = []
      ++ optional cfg.networking.enable "rndis"
      ++ optional cfg.usb.adbd "ffs"
    ;

    # FIXME : split into "old style" (/sys/class/android_usb/android0/) and
    # the newer mainline style (configfs + functionfs)
    init = lib.mkOrder AFTER_DEVICE_INIT ''
    '';
    extraUtils = with pkgs; []
    ++ optional cfg.usb.adbd { package = adbd; extraCommand = "cp -fpv ${glibc.out}/lib/libnss_files.so.* $out/lib"; }
    ;
  };
}
