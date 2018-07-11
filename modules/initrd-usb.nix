{ config, lib, pkgs, ... }:

with lib;
with import ./initrd-order.nix;

let
  cfg = config.mobile.boot.stage-1;
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
      type = types.listOf types.string;
      default = [];
      description = ''
        `android_usb` features to enable.
      '';
    };
    adbd = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Enables adbd on the device.
      '';
    };
  };

  config.mobile.boot.stage-1 = lib.mkIf cfg.usb.enable {
    usb.features = []
      ++ optional cfg.networking.enable "rndis"
      ++ optional cfg.usb.adbd "adb"
    ;
    # TODO: Only run, when we have the android usb driver
    init = lib.mkOrder AFTER_DEVICE_INIT ''
      # Setting up Android-specific USB.
      (
      SYS=/sys/class/android_usb/android0
      if [ -e "$SYS" ]; then
        printf "%s" "0"    > "$SYS/enable"
        printf "%s" "18D1" > "$SYS/idVendor"
        printf "%s" "D001" > "$SYS/idProduct"
        printf "%s" "${concatStringsSep "," cfg.usb.features}" > "$SYS/functions"
        sleep 0.5
        printf "%s" "1" > "$SYS/enable"
        sleep 1

        ${optionalString cfg.usb.adbd "adbd &\n"}
      fi
      )
    '';
    extraUtils = with pkgs; []
    ++ optional cfg.usb.adbd { package = adbd; extraCommand = "cp -fpv ${glibc.out}/lib/libnss_files.so.* $out/lib"; }
    ;
  };
}
