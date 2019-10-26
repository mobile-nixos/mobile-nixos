{ config, lib, pkgs, ... }:

with lib;
with import ./initrd-order.nix;

{
  options.mobile.adbd = {
    enable = mkOption {
      type = types.bool;
      default = config.mobile.system.type == "android";
      description = ''
        Enables adbd on the device.
      '';
    };
  };

  config = lib.mkIf config.mobile.adbd.enable {
    assertions = [
      { assertion = config.mobile.system.type == "android";
        message = "adb is only available on Android";
      }
      { assertion = config.mobile.boot.stage-1.usb.enable;
        message = "adb requires mobile.boot.stage-1.usb.enable = true";
      }
    ];

    mobile.boot.stage-1 = {
      usb.features = [ "ffs" ];

      init = lib.mkOrder AFTER_DEVICE_INIT ''
        (
        mkdir -p /dev/usb-ffs/adb
        mount -t functionfs adb /dev/usb-ffs/adb/
        sleep 0.1
        adbd &
        )
      '';

      extraUtils = with pkgs; [{
        package = adbd;
        extraCommand = ''cp -fpv "${glibc.out}"/lib/libnss_files.so.* "$out"/lib/'';
      }];
    };

    boot.postBootCommands = ''
      # Restart adbd early during stage-2
      adbd_pid=$(${pkgs.procps}/bin/pidof adbd)
      [ -n "$adbd_pid" ] && kill "$adbd_pid"
      ${pkgs.adbd}/bin/adbd &
    '';
  };
}
