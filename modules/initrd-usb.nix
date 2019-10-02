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
      # Setting up Android-specific USB.
      (
      echo "Preparing usb gadgets"

      SYS=/sys/class/android_usb/android0

      if [ -e "$SYS/enable" ]; then
        mkdir -p /dev/usb-ffs/adb
        mount -t functionfs adb /dev/usb-ffs/adb/

        printf "%s" "0"    > "$SYS/enable"
        printf "%s" "18D1" > "$SYS/idVendor"
        printf "%s" "D001" > "$SYS/idProduct"
        printf "%s" "0"    > "$SYS/bDeviceClass"
        printf "%s" "${concatStringsSep "," cfg.usb.features}" > "$SYS/functions"
        printf "%s" "mobile-nixos" > "$SYS/iManufacturer"
        printf "%s" "${device_name}" > "$SYS/iProduct"
        printf "%s" "0123456789" > "$SYS/iSerial"

        sleep 0.1
        printf "%s" "1" > "$SYS/enable"
        sleep 0.1

      # Bad assumption to be "else"...
      else
        (
          mkdir -p /config
          mount -t configfs configfs /config

          cd /config/usb_gadget

          mkdir -p g1/strings/0x409
          printf "%s" "0x18D1" > "g1/idVendor"
          printf "%s" "0xD001" > "g1/idProduct"
          printf "%s" "mobile-nixos"   > "g1/strings/0x409/manufacturer"
          printf "%s" "${device_name}" > "g1/strings/0x409/product"

          mkdir -p g1/configs/c.1/strings/0x409
          printf "%s" "rndis" > g1/configs/c.1/strings/0x409/configuration

          for f in ${rndis_f_name}.usb0; do
            mkdir -p g1/functions/$f
            ln -s g1/functions/$f g1/configs/c.1/$f
          done

          (cd /sys/class/udc; echo *) > g1/UDC
        )
      fi
      echo "Finished setting up configfs"

      # Always start adbd... what's the worst that could happen?
      ${optionalString cfg.usb.adbd "adbd &\n"}
      )
    '';
    extraUtils = with pkgs; []
    ++ optional cfg.usb.adbd { package = adbd; extraCommand = "cp -fpv ${glibc.out}/lib/libnss_files.so.* $out/lib"; }
    ;
  };
}
