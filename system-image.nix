#
# nix-build nixos -I nixos-config=system-image.nix -A config.system.build.sdImage
#
{ config, lib, pkgs, ... }:

let
  inherit (import <nixpkgs> {}) path;

  extlinux-conf-builder =
    import (path + "/nixos/modules/system/boot/loader/generic-extlinux-compatible/extlinux-conf-builder.nix") {
      inherit pkgs;
    };
in
{
  imports = [
    (path + "/nixos/modules/installer/cd-dvd/sd-image.nix")
    (path + "/nixos/modules/profiles/base.nix")
    (path + "/nixos/modules/profiles/installation-device.nix")
  ];
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  # FIXME: this probably should be in installation-device.nix

  sdImage = {
    populateBootCommands = ''
      ${extlinux-conf-builder} -t 3 -c ${config.system.build.toplevel} -d ./boot
    '';
  };
}
