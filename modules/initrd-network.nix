{ config, lib, pkgs, ... }:

with lib;
with import ./initrd-order.nix;

let
  cfg = config.mobile.boot.stage-1.networking;
  IP = cfg.IP;
  hostIP = cfg.hostIP;
in
{
  # FIXME : this is probably incomplete.
  options.mobile.boot.stage-1.networking = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enables networking.
      '';
    };
    IP = mkOption {
      type = types.str;
      default = "172.16.42.1";
      description = ''
        IP address for the USB networking gadget.
      '';
    };
    hostIP = mkOption {
      type = types.str;
      default = "172.16.42.2";
      description = ''
        IP address for the USB networking gadget.
      '';
    };
  };

  config.mobile.boot.stage-1 = lib.mkIf cfg.enable {
    init = lib.mkOrder NETWORK_INIT ''
      start_udhcpd() {
        # Only run once
        [ -e /etc/udhcpd.conf ] && return

        # Get usb interface
        INTERFACE=""

        # Try five times
        for try in 1 2 3 4 5; do
          echo "Trying to identify interface ($try/5)"

          ifconfig rndis0 "${IP}" && INTERFACE=rndis0
          if [ -z $INTERFACE ]; then
            ifconfig usb0 "${IP}" && INTERFACE=usb0
          fi
          if [ -z $INTERFACE ]; then
            ifconfig eth0 "${IP}" && INTERFACE=eth0
          fi

          if [ -z $INTERFACE ]; then
            sleep 1
          else
            break
          fi
        done

        if [ -z $INTERFACE ]; then
          echo "Couldn't identify interface..."
          return
        fi

        echo "Identified interface $INTERFACE"

        # Create /etc/udhcpd.conf
        {
          echo "start ${hostIP}"
          echo "end ${hostIP}"
          echo "auto_time 0"
          echo "decline_time 0"
          echo "conflict_time 0"
          echo "lease_file /var/udhcpd.leases"
          echo "interface $INTERFACE"
          echo "option subnet 255.255.255.0"
        } >/etc/udhcpd.conf
        echo "Start the dhcpcd daemon (forks into background)"
        udhcpd
      }

      start_udhcpd
    '';
  };
}
