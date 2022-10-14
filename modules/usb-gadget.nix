{ config, lib, pkgs, ... }:

{
  # Ensure configfs is mounted if needed.
  fileSystems."/sys/kernel/config" = lib.mkIf (config.mobile.usb.mode == "gadgetfs") {
    device = "none";
    fsType = "configfs";
  };
}
