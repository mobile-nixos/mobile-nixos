{ config, lib, pkgs, ... }:

let
  inherit (lib) mkMerge mkOrder;
in
with import ./initrd-order.nix;
{
  config = mkMerge [
    {
      # This is +1 to DEVICE_INIT and not AFTER_DEVICE_INIT because this is
      # tighly coupled with DEVICE_INIT. The other parts of DEVICE_INIT setup
      # the basic filesystem layout and fs, here udev fills /dev/ with the
      # expected richer devices.
      mobile.boot.stage-1.init = mkOrder (DEVICE_INIT + 1) ''
        systemd-udevd --daemon
        udevadm trigger --action=add
        udevadm settle
      '';
    }
    {
      # Probably not needed, but ensures all block devices are available, even
      # newly detected ones.
      mobile.boot.stage-1.init = mkOrder (SWITCH_ROOT_INIT - 1) ''
        udevadm settle
      '';
    }
    {
      # Exits the udev daemon that was used for initrd.
      mobile.boot.stage-1.init = mkOrder AFTER_SWITCH_ROOT_INIT ''
        udevadm control --exit
      '';
    }
  ];
}
