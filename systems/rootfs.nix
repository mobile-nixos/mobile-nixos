# This builds a rootfs image (ext4) from the current configuration.
{ config, lib, pkgs, ... }:

let
  inherit (config.boot) growPartition;
  inherit (lib) optionalString;
in
{
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = false;

  boot.growPartition = lib.mkDefault true;

  system.build.rootfs =
    pkgs.imageBuilder.fileSystem.makeExt4 {
      name = "NIXOS_SYSTEM";
      partitionID = "44444444-4444-4444-8888-888888888888";
      populateCommands =
      let
        closureInfo = pkgs.buildPackages.closureInfo { rootPaths = config.system.build.toplevel; };
      in
      ''
        mkdir -p ./nix/store
        echo "Copying system closure..."
        while IFS= read -r path; do
          echo "  Copying $path"
          cp -prf "$path" ./nix/store
        done < "${closureInfo}/store-paths"
        echo "Done copying system closure..."
        cp -v ${closureInfo}/registration ./nix-path-registration
      '';

      # Give some headroom for initial mounting.
      extraPadding = pkgs.imageBuilder.size.MiB 20;
    }
  ;

  # FIXME: this is not a rootfs!
  system.build.diskImage = 
    pkgs.imageBuilder.diskImage.makeMBR {
      name = "mobile-nixos";
      diskID = "01234567";
      partitions = [
        # FIXME : initrd how?
        config.system.build.rootfs
      ];
    }
  ;

  boot.postBootCommands = ''
    # On the first boot do some maintenance tasks
    if [ -f /nix-path-registration ]; then
      # Register the contents of the initial Nix store
      ${config.nix.package.out}/bin/nix-store --load-db < /nix-path-registration

      # nixos-rebuild also requires a "system" profile and an /etc/NIXOS tag.
      touch /etc/NIXOS
      ${config.nix.package.out}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system

      # Prevents this from running on later boots.
      rm -f /nix-path-registration
    fi
  '';

  fileSystems = {
    "/" = {
      # Expected to be installed as `system` partition on android-like.
      # Thus the name.
      # TODO: move into the android system type.
      device = "/dev/disk/by-label/NIXOS_SYSTEM";
      fsType = "ext4";
    };
  };
}
