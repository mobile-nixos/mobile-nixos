# This is intended to be used to produce a bootable `boot.img` with adbd, and
# dropbear enabled. You would, in turn, use it to "flash" a dumb system.img file
# to a partition, like userdata.
#
# *CAUTION* : there is no protection against flashing over the wrong partition.
# Read about the usual pitfalls in the Android section of the documentation.
{ config, lib, pkgs, ... }:

let
  inherit (lib) mkMerge mkOrder;
  inherit (import ../../modules/initrd-order.nix) BEFORE_SWITCH_ROOT_INIT READY_INIT;

  # TODO : make this a part of the device knowledge base.
  # TODO : allow more complex layouts, e.g. LVM over system+data partitions.
  userdata_device = "/dev/disk/by-partlabel/userdata";
in
{
  config = mkMerge [
    {
      # Ensures we don't quit stage-1
      mobile.boot.stage-1.shell.enable = true;

      # Enables networking and ssh in stage-1 !
      mobile.boot.stage-1.networking.enable = true;
      mobile.boot.stage-1.ssh.enable = true;

      # Make sure we don't burn the battery, then also show a useful
      # status indication about readyness...
      mobile.boot.stage-1.init = mkOrder READY_INIT ''
        for f in /sys/bus/cpu/devices/*/online; do echo 1 > $f; done
        echo 6 > /sys/class/leds/lcd-backlight/brightness

        (
        echo ""
        echo "+----------------------------+"
        echo "| Be mindful of your actions |"
        echo "|   they have consequences   |"
        echo "+----------------------------+"
        echo ""
        echo "The expected location for userdata is:"
        echo "  ${userdata_device}"
        echo ""
        echo "If found, it has been symlinked to /dev/userdata"
        echo ""
        ) >> /etc/warning.txt
        echo "cat /etc/warning.txt" >> /etc/profile

        # Yellow means it's close to ready
        ply-image --clear=0xFFFB5A &

        # This is cheesy, but often ssh isn't ready AT green.
        # This small delay is likely satisfactory.
        (sleep 3 ;

        # Checks if `userdata` is found.
        if [ -e "${userdata_device}" ]; then
          ply-image --clear=0x5FDD55
          ln -sf "${userdata_device}" "/dev/userdata"
        else
          # Red means bad...
          # You probably need to ssh into and inspect what's up.
          ply-image --clear=0xFF0000
        fi

        ) &
      '';
    }
  ];
}
