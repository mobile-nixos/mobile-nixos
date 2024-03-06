{ lib, pkgs, ... }:

let
  inherit (lib) mkDefault mkForce;
in
{
  # Make the system rootfs different enough that mixing stage-1 and stage-2
  # will fail and not have weird unexpected behaviours.
  mobile.generatedFilesystems = {
    rootfs = mkDefault {
      label = mkForce "MOBILE_INSTALLER";
      ext4.partitionID = mkForce "12345678-9000-0001-0000-D00D00000001";
    };
  };

  fileSystems = {
    "/" = mkDefault {
      # Handled within stage-2
      # Do not disable autoResize, it'll take more time, but this does `e2fsck`
      # which is required for the other resize2fs invocation to work properly in stage-2 :/
      # autoResize = mkForce false;
    };
  };

  # It's acceptable here to lose some boot time to resizing the partition all the time.
  # Logic is the same as SD card enlargement.
  boot.initrd.systemd.repart.enable = true;

}
