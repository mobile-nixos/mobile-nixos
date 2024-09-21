# This provides `build.rootfs`, which is the rootfs image (ext4) built from
# the current configuration.
{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf mkOption optionalString types;
  inherit (config.mobile._internal) compressLargeArtifacts;
  inherit (pkgs) buildPackages;
  rootfsLabel = config.mobile.generatedFilesystems.rootfs.label;
in
{
  options = {
    mobile = {
      rootfs = {
        enableDefaultConfiguration = mkOption {
          type = types.bool;
          default = config.mobile.enable;
          description = ''
            Whether some of the rootfs configuration is managed by Mobile NixOS or not.
          '';
        };
        rehydrateStore = mkOption {
          type = types.bool;
          default = config.nix.enable;
          defaultText = lib.literalExpression "config.nix.enable";
          description = ''
            Whether to rehydrate the store at first boot or not.

            The only reason you would disable this is to build a target system that has no Nix binaries.
          '';
        };
      };
    };
  };

  config = mkIf (config.mobile.rootfs.enableDefaultConfiguration) {
    boot.growPartition = lib.mkDefault true;

    mobile.generatedFilesystems.rootfs = lib.mkDefault {
      filesystem = "ext4";
      label = "NIXOS_SYSTEM";
      ext4.partitionID = "44444444-4444-4444-8888-888888888888";

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
      extraPadding = pkgs.image-builder.helpers.size.MiB 20;

      location = "/rootfs.img${optionalString compressLargeArtifacts ".zst"}";

      # FIXME: See #117, move compression into the image builder.
      # Zstd can take a long time to complete successfully at high compression
      # levels. Increasing the compression level could lead to timeouts.
      additionalCommands = optionalString compressLargeArtifacts ''
        echo ":: Compressing rootfs image"
        (PS4=" $ "; set -x
        cd $out_path
        # Hacky, but the img path here already has .zst appended.
        # Let's rename it (we assume rootfs.img) and do the compression here.
        mv "$img" "rootfs.img"
        time ${buildPackages.zstd}/bin/zstd -10 --rm "rootfs.img"
        )
      '' + ''
        echo ":: Adding hydra-build-products"
        (PS4=" $ "; set -x
        mkdir -p $out_path/nix-support
        cat <<EOF > $out_path/nix-support/hydra-build-products
        file rootfs${optionalString compressLargeArtifacts "-zstd"} $img
        EOF
        )
      '';
    };

    boot.postBootCommands = mkIf (config.mobile.rootfs.rehydrateStore) ''
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
      "/" = lib.mkDefault {
        device = "/dev/disk/by-label/${rootfsLabel}";
        fsType = "ext4";
        autoResize = true;
      };
    };

    # FIXME: Move this in a proper module + task for the filesystem.
    # This is a "wrong" assumption, that only holds through since we are setting
    # fileSystems."/".autoResize to true here.
    mobile.boot.stage-1.extraUtils = [
      { package = pkgs.e2fsprogs; }
    ];
  };
}
