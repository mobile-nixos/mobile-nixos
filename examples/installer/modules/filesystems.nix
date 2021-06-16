{ lib, ... }:

let
  inherit (lib) mkDefault mkForce;
in
{
  # Make the system rootfs different enough that mixing stage-1 and stage-2
  # will fail and not have weird unexpected behaviours.
  mobile.generatedFilesystems = {
    rootfs = mkDefault {
      label = mkForce "MOBILE_INSTALLER";
      id    = mkForce "12345678-9000-0001-0000-D00D00000001";
    };
  };

  fileSystems =
    let
      tmpfsConf = {
        device = "tmpfs";
        fsType = "tmpfs";
        neededForBoot = true;
      };
    in
    {
      "/" = mkDefault {
        autoResize = mkForce false;
      };
      # Nothing is saved, except for the nix store being rehydrated.
      "/tmp"     = tmpfsConf;
      "/var/log" = tmpfsConf;
      "/home"    = tmpfsConf;
    }
  ;
}
