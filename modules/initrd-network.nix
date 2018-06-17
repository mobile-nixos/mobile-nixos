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
      default = true;
      description = ''
        Enables networking.
        CURRENT CONFIGURATION ALSO OPENS ACCESS TO ALL WITHOUT A PASSWORD NOR SSH KEY.
      '';
    };
    IP = mkOption {
      type = types.string;
      default = "172.16.42.1";
      description = ''
        IP address for the USB networking gadget.
      '';
    };
    hostIP = mkOption {
      type = types.string;
      default = "172.16.42.2";
      description = ''
        IP address for the USB networking gadget.
      '';
    };
  };

  config.mobile.boot.stage-1 = lib.mkIf cfg.enable {
    init = lib.mkOrder NETWORK_INIT ''
      setup_usb_network_android() {
        # Only run, when we have the android usb driver
        SYS=/sys/class/android_usb/android0
        [ -e "$SYS" ] || return
        # Do the setup
        printf "%s" "0" >"$SYS/enable"
        printf "%s" "18D1" >"$SYS/idVendor"
        printf "%s" "D001" >"$SYS/idProduct"
        printf "%s" "rndis" >"$SYS/functions"
        printf "%s" "1" >"$SYS/enable"
      }
      setup_usb_network_configfs() {
        CONFIGFS=/config/usb_gadget
        [ -e "$CONFIGFS" ] || return
        mkdir $CONFIGFS/g1
        printf "%s" "18D1" >"$CONFIGFS/g1/idVendor"
        printf "%s" "D001" >"$CONFIGFS/g1/idProduct"
        mkdir $CONFIGFS/g1/strings/0x409
        mkdir $CONFIGFS/g1/functions/rndis.usb0
        mkdir $CONFIGFS/g1/configs/c.1
        mkdir $CONFIGFS/g1/configs/c.1/strings/0x409
        printf "%s" "rndis" > $CONFIGFS/g1/configs/c.1/strings/0x409/configuration
        ln -s $CONFIGFS/g1/functions/rndis.usb0 $CONFIGFS/g1/configs/c.1
        echo "$(ls /sys/class/udc)" > $CONFIGFS/g1/UDC
      }
      setup_usb_network() {
        # Only run once
        _marker="/tmp/_setup_usb_network"
        [ -e "$_marker" ] && return
        touch "$_marker"
        echo "Setup usb network"
        setup_usb_network_android
        setup_usb_network_configfs
      }
      start_udhcpd() {
        # Only run once
        [ -e /etc/udhcpd.conf ] && return

        # Get usb interface
        INTERFACE=""
        ifconfig rndis0 "${IP}" && INTERFACE=rndis0
        if [ -z $INTERFACE ]; then
          ifconfig usb0 "${IP}" && INTERFACE=usb0
        fi
        if [ -z $INTERFACE ]; then
          ifconfig eth0 "${IP}" && INTERFACE=eth0
        fi
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

      setup_usb_network
      start_udhcpd
    '';
  };
}
