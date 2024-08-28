{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkOption
    types
  ;
in
{
  options.mobile.adbd = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enables adbd on the device.
      '';
    };
  };

  config = lib.mkIf config.mobile.adbd.enable {
    assertions = [
      { assertion = config.mobile.boot.stage-1.usb.enable;
        message = "adb requires mobile.boot.stage-1.usb.enable = true";
      }
    ];

    mobile.boot.stage-1 = {
      usb.features = [ "adb" ];

      extraUtils = [{
        package = pkgs.adbd;
        extraCommand = ''cp -fpv "${pkgs.glibc.out}"/lib/libnss_files.so.* "$out"/lib/'';
      }];
    };

    # TODO: `teardown` on the stage-1 adb task, and execute it before switch_root
    boot.postBootCommands = ''
      # Kill adbd early during stage-2
      ${pkgs.procps}/bin/pkill -x adbd
    '';

    # This service assumes there was a single gadget configured during stage-1
    # for ffs and adb use, and that this gadget is to be re-used.
    # TODO: self-contained configuration of the gadget with gadget-tool here.
    systemd.services.adbd = {
      description = "ADB Daemon for stage-2";
      wantedBy = [ "multi-user.target" ];
      enable = true;
      script = ''
        ${pkgs.adbd}/bin/adbd &

        # Wait a bit to ensure the ffs (functionfs) component is started.
        sleep 1

        # NOTE: the ffs (functionfs) userspace component needs to already
        #       be running when we "enable" the gadget.
        #       Else we will get errno -19, ENODEV.
        if [ -e /sys/kernel/config/usb_gadget ]; then
          cd /sys/kernel/config/usb_gadget
          for gadget in * ; do
            if test -n $gadget/UDC ; then
              # honestly this does nothing more than "echo",
              # am only using gt to show that it exists
              ${pkgs.gadget-tool}/bin/gt enable $gadget
            fi
          done
        fi

        wait
      '';
    };
  };
}
