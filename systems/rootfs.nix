# This builds a rootfs image (ext4) from the current configuration.
{ config, lib, pkgs, ... }:

{
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = false;

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
      # FIXME : fixup the partition autoexpand.
      extraPadding = pkgs.imageBuilder.size.MiB 500;
    }
  ;

  # FIXME: this is not a rootfs!
  system.build.diskImage = 
    throw "The system needs to implement `diskImage`."
  ;

  #pkgs.runCommandNoCC "mobile-nixos-rootfs" {} ''
  #  echo "${config.system.build.toplevel}" > $out
  #'';

  boot.postBootCommands = ''
    # On the first boot do some maintenance tasks
    if [ -f /nix-path-registration ]; then
      ${""
      # TODO : optionally resize NIXOS_SYSTEM, depending on the target.
      # # Figure out device names for the boot device and root filesystem.
      # rootPart=$(readlink -f /dev/disk/by-label/NIXOS_SYSTEM)
      # bootDevice=$(lsblk -npo PKNAME $rootPart)

      # # Resize the root partition and the filesystem to fit the disk
      # echo ",+," | sfdisk -N2 --no-reread $bootDevice
      # ${pkgs.parted}/bin/partprobe
      # ${pkgs.e2fsprogs}/bin/resize2fs $rootPart
      }

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
