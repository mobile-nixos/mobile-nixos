{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkIf
    mkOption
    optionalString
    types
  ;
in
{
  options = {
    mobile = {
      rootfs = {
        useSquashfs = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Whether the rootfs (and system accordingly) will be a squashfs.

            Additional setup is needed with squashfs.
          '';
        };
      };
    };
  };
  config = mkIf (config.mobile.rootfs.useSquashfs) {
    mobile.generatedFilesystems = {
      rootfs = lib.mkDefault {
        filesystem = lib.mkForce "squashfs";                                    
      };
    };

    fileSystems = {
      # Squashfs usage
      "/" = lib.mkImageMediaOverride {
        device = "tmpfs";
        fsType = "tmpfs";
        neededForBoot = true;
      };
      "/nix/.ro-store" = lib.mkImageMediaOverride {
        autoResize = false;
        label = lib.mkForce null;
        fsType = lib.mkForce "squashfs";
        device = lib.mkForce "/dev/disk/by-partlabel/${config.mobile.generatedFilesystems.rootfs.label}";
        neededForBoot = true;
      };
      "/nix/.rw-store" = lib.mkImageMediaOverride {
        fsType = "tmpfs";
        options = [ "mode=0755" ];
        neededForBoot = true;
      };
      "/nix/store" = lib.mkImageMediaOverride {
        fsType = "overlay";
        device = "overlay";
        neededForBoot = true;
        options = [
          "lowerdir=/nix/.ro-store/nix/store"
          "upperdir=/nix/.rw-store/store"
          "workdir=/nix/.rw-store/work"
        ];
        depends = [
          "/nix/.ro-store"
          "/nix/.rw-store"
        ];
      };
      # Fishes `nix-path-registration` out of the read-only “rootfs” layer.
      # This is because the overlayfs mounting is only made for the Nix store.
      # The only other thing on the FS is this file, and needs to be at the root.
      "/nix-path-registration" = lib.mkImageMediaOverride {
        neededForBoot = true;
        device = "/nix/.ro-store/nix-path-registration";
        options = [ "bind" ];
      };
    };

    mobile.boot.stage-1.kernel.additionalModules = (lib.mkIf config.mobile.boot.stage-1.kernel.modular [
      "squashfs"
      "overlay"
    ]);
  };
}
