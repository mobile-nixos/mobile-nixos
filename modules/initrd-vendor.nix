# This module handles well-known "vendor" partitions.
#
# Relevant upstream documentation:
#  * https://www.kernel.org/doc/html/v4.14/driver-api/firmware/fw_search_path.html
#
# Note that we'll be using `firmware_class.path=/vendor/firmware` on the
# command-line to make the firmware path known ASAP without requiring run-time
# configuration. The NixOS stage-2 will configure `/sys/module/firmware_class/parameters/path`
# as expected.
{ config, lib, ... }:

let
  inherit (lib) types;
  inherit (config.mobile.system) vendor;
in
{
  options = {
    mobile.system.vendor.partition = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Path to a partition with firmware files built-in to the device";
      internal = true;
    };
  };
  config = lib.mkIf (vendor.partition != null) {
    boot.kernelParams = [
      "firmware_class.path=/vendor/firmware"
    ];

    boot.specialFileSystems = {
      "/vendor" = {
        device = vendor.partition;
        fsType = "ext4";
        options = [ "ro" "nosuid" "noexec" "nodev" ];
      };
    };
  };
}
