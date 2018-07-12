# This module creates a system.img file built and sized to flash to an android-device.
#
# The derivation for the image will be placed in
# config.system.build.system_img

# FIXME : this is a bit of a hack.

{
  mobile_config
}:

{ config, lib, pkgs, ... }:

with lib;

let
  rootfsImage = import <nixpkgs/nixos/lib/make-ext4-fs.nix> {
    inherit pkgs;
    inherit (config.systemImage) storePaths;
    volumeLabel = "NIXOS_SD";
  };
in
{
  options.systemImage = {
    imageBaseName = mkOption {
      default = "nixos-system";
      description = ''
        Prefix of the name of the generated image file.
      '';
    };

    storePaths = mkOption {
      type = with types; listOf package;
      example = literalExample "[ pkgs.stdenv ]";
      description = ''
        Derivations to be included in the Nix store in the generated SD image.
      '';
    };

    bootSize = mkOption {
      type = types.int;
      default = 120;
      description = ''
        Size of the /boot partition, in megabytes.
      '';
    };
  };

  config = {
    fileSystems = {
      "/" = {
        device = "/dev/disk/by-label/NIXOS_SD";
        fsType = "ext4";
      };
    };

    boot.kernelPackages =
    lib.makeExtensible (self: with self; {
      inherit (mobile_config.mobile.device.info) kernel;
    })
    ;#pkgs.linuxPackagesFor mobile_config.mobile.device.info.kernel;

    systemImage.storePaths = [ config.system.build.toplevel ];

    system.build.systemImage = rootfsImage;
    #pkgs.stdenv.mkDerivation {
    #  name = "mobile-nixos_system-android_system.img";

    #  buildInputs = with pkgs; [ e2fsprogs mtools libfaketime utillinux ];

    #  buildCommand = ''
    #    cp "${rootfsImage}" "$img"
    #  '';
    #};

    boot.postBootCommands = ''
      # On the first boot do some maintenance tasks
      if [ -f /nix-path-registration ]; then
        # Figure out device names for the boot device and root filesystem.
        rootPart=$(readlink -f /dev/disk/by-label/NIXOS_SD)
        # bootDevice=$(lsblk -npo PKNAME $rootPart)
        # 
        # # Resize the root partition and the filesystem to fit the disk
        # echo ",+," | sfdisk -N2 --no-reread $bootDevice
        # ${pkgs.parted}/bin/partprobe
        ${pkgs.e2fsprogs}/bin/resize2fs $rootPart

        # Register the contents of the initial Nix store
        ${config.nix.package.out}/bin/nix-store --load-db < /nix-path-registration

        # nixos-rebuild also requires a "system" profile and an /etc/NIXOS tag.
        touch /etc/NIXOS
        ${config.nix.package.out}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system

        # Prevents this from running on later boots.
        rm -f /nix-path-registration
      fi
    '';

    # FIXME https://github.com/ElvishJerricco/cross-nixos-aarch64/blob/master/configuration.nix
    security.polkit.enable = false;
    services.udisks2.enable = false;
    programs.command-not-found.enable = false;
    system.boot.loader.kernelFile = lib.mkForce "Image";
    services.nixosManual.enable = lib.mkOverride 0 false;
    nix.checkConfig = false;
    services.klogd.enable = false;

    nixpkgs.crossSystem = mobile_config.nixpkgs.crossSystem;
    system.nixos.stateVersion = "18.09";

    systemd.services.sshd.wantedBy = lib.mkOverride 0 ["multi-user.target"];

    # https://github.com/ElvishJerricco/cross-nixos-aarch64/blob/master/sd-image-aarch64.nix
    boot.loader.grub.enable = false;
    boot.loader.generic-extlinux-compatible.enable = true;
    boot.consoleLogLevel = lib.mkDefault 7;
    users.extraUsers.root.initialHashedPassword = "";

    # HACK!
    # Removing `(isYes "MODULES")` would be preferrable.
    system.requiredKernelConfig = lib.mkForce [];
  };
}
