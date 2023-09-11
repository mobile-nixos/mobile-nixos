{ lib, ... }:
{
  imports = [
    ../../common-configuration.nix
  ];

  # This system is not expected to be bootable.
  fileSystems = {
    "/" = {
      device = "tmpfs";
      fsType = "tmpfs";
    };
  };
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = false;

  # Documentation build will be different, so comparing `toplevel` would fail.
  # Different why? New options!
  documentation.enable = lib.mkOverride 10 false;

  # Unimportant, but keeps the eval log cleaner.
  system.stateVersion = "22.05";

  # ¯\_(ツ)_/¯
  services.getty.autologinUser = "root";
}
