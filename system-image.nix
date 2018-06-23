#
# nix-build nixos -I nixos-config=system-image.nix -A config.system.build.sdImage
#
{ config, lib, pkgs, ... }:

let
  extlinux-conf-builder =
    import <nixpkgs/nixos/modules/system/boot/loader/generic-extlinux-compatible/extlinux-conf-builder.nix> {
      inherit pkgs;
    };
in
{
  imports = [
    # FIXME : use overlay's `pkgs.path` instead of `<nixpkgs>`?
    # while evaluating the module argument `pkgs' in "[...]/mobile-nixos/system-image.nix":
    # infinite recursion encountered, at /nix/store/8vczq3489dl8xa5s7ksqyqkbirmpd3sb-source/lib/modules.nix:163:28
    # (pkgs.path + "/nixos/modules/installer/cd-dvd/sd-image.nix")
    <nixpkgs/nixos/modules/installer/cd-dvd/sd-image.nix>
  ];
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  sdImage = {
    populateBootCommands = ''
      ${extlinux-conf-builder} -t 3 -c ${config.system.build.toplevel} -d ./boot
    '';
  };
}
