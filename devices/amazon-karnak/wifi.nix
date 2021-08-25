# Wi-Fi
#
# FIXME:
# We currently use the binary .ko files from <https://github.com/mt8163/android_vendor_amazon_karnak>.
# The source code to the modules may be found in the Amazon source tarball,
# and we need to integrate it into the kernel tree.
#
# The following things need to happen for Wi-Fi to work:
# 1. wmt_drv and wmt_chrdev_wifi are loaded
# 2. mtinit finishes
# 3. wlan_drv_gen2 is loaded (this cannot be loaded earlier)
# 4. mtdaemon starts
# 5. echo 1 > /dev/wmtWifi

{ lib, pkgs, config, ... }:
let
  firmware = config.mobile.device.firmware;
in {
  config = lib.mkIf config.nixpkgs.config.allowUnfree {
    # Steps 1 & 2
    systemd.services.mtinit = {
      path = with pkgs; [ kmod openmttools ];
      script = ''
        insmod ${firmware}/lib/modules/wmt_drv.ko
        insmod ${firmware}/lib/modules/wmt_chrdev_wifi.ko

        mtinit
      '';

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
      };

      # mtinit must not be run twice
      restartIfChanged = false;
    };

    # Steps 3 & 4
    systemd.services.mtdaemon = {
      requires = [ "mtinit.service" ];
      after = [ "mtinit.service" ];

      path = with pkgs; [ kmod openmttools ];
      script = ''
        insmod ${firmware}/lib/modules/wlan_drv_gen2.ko

        mtdaemon -p ${firmware}/lib/firmware
      '';
    };

    # Step 5
    systemd.services.activate-wmt-wifi = {
      requires = [ "mtdaemon.service" ];
      after = [ "mtdaemon.service" ];

      wantedBy = [ "network-online.target" ];

      script = ''
        sleep 2
        echo 1 > /dev/wmtWifi
      '';

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
      };
    };
  };
}
