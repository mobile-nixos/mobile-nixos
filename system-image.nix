#
# nix-build nixos -I nixos-config=system-image.nix -A config.system.build.sdImage
#
{ config, lib, pkgs, ... }:

let
  path = (import ./overlay).path;
  extlinux-conf-builder =
    import (path + "/nixos/modules/system/boot/loader/generic-extlinux-compatible/extlinux-conf-builder.nix") {
      inherit pkgs;
    };
in
{
  imports = [
    # FIXME : use `pkgs.path` instead of this hack.
    # while evaluating the module argument `pkgs' in "[...]/mobile-nixos/system-image.nix":
    # infinite recursion encountered, at /nix/store/8vczq3489dl8xa5s7ksqyqkbirmpd3sb-source/lib/modules.nix:163:28
    # (pkgs.path + "/nixos/modules/installer/cd-dvd/sd-image.nix")
    (path + "/nixos/modules/installer/cd-dvd/sd-image.nix")
    (path + "/nixos/modules/profiles/base.nix")
    (path + "/nixos/modules/profiles/installation-device.nix")
  ];
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  sdImage = {
    populateBootCommands = ''
      ${extlinux-conf-builder} -t 3 -c ${config.system.build.toplevel} -d ./boot

      # This is a crutch.
      # This points to the last generation's `init`.
      cat >> ./boot/init-path <<EOF
      ${config.system.build.toplevel}/init
      EOF
    '';
  };
}
