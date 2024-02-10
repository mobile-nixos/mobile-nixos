{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf mkOption types;
in
{
  options = {
    mobile = {
      bootloader = {
        enable = mkOption {
          type = types.bool;
          default = config.mobile.enable;
          description = lib.mdDoc ''
            Whether the bootloader **configuration** for Mobile NixOS
            is enabled.

            Installation and management of the Mobile NixOS bootloading
            components is not implemented at this point in time.
            (e.g. flashing boot.img on android, boot partition on other systems.)
          '';
        };
      };
    };
  };

  config = mkIf (config.mobile.bootloader.enable) {
    boot.loader.grub.enable = false;
    boot.loader.generic-extlinux-compatible.enable = false;

    # Shut up warning about not having a boot loader.
    system.build.installBootLoader = lib.mkDefault "${pkgs.coreutils}/bin/true";
  };
}

