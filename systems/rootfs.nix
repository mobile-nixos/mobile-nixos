# This builds a rootfs image (ext4) from the current configuration.
{ config, lib, pkgs, ... }:

let
  inherit (pkgs) hostPlatform buildPackages imageBuilder;
  inherit (config.boot) growPartition;
  inherit (lib) optionalString;
in
{
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = false;

  boot.growPartition = lib.mkDefault true;

  system.build.rootfs =
    if hostPlatform.system == builtins.currentSystem
    then (imageBuilder.fileSystem.makeExt4 {
      bootable = true;
      name = "NIXOS_SYSTEM";
      partitionID = "44444444-4444-4444-8888-888888888888";
      populateCommands =
        let
          closureInfo = buildPackages.closureInfo { rootPaths = config.system.build.toplevel; };
        in ''
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
      extraPadding = imageBuilder.size.MiB 20;
    })
    else (builtins.trace "WARNING: Using dummy empty filesystem as we're cross-compiling."
      (imageBuilder.fileSystem.makeExt4 {
        bootable = true;
        name = "DUMMY"; # Using the "wrong" filesystem label here by design.
        partitionID = "33333333-4444-4444-8888-888888888888"; # Using the "wrong" GUID here by design.
        size = imageBuilder.size.MiB 10;
        populateCommands = ''
          # no-op
        '';
      })
    )
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
      autoResize = true;
    };
  };

  # FIXME: Move this in a proper module + task for the filesystem.
  # This is a "wrong" assumption, that only holds through since we are setting
  # fileSystems."/".autoResize to true here.
  mobile.boot.stage-1.extraUtils = with pkgs; [
    { package = e2fsprogs; }
  ];
}
