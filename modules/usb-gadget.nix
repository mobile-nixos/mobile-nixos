{ config, lib, pkgs, ... }:

{
  fileSystems = lib.mkIf (config.mobile.usb.mode == "gadgetfs") {
    # Ensure configfs is mounted, when needed.
    "/sys/kernel/config" = {
      device = "none";
      fsType = "configfs";
    };
  };
}
