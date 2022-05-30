{ config, lib, ... }:

let
  inherit (config.mobile.rootfs.shared) enabled;
  inherit (lib) mkIf mkOption types;
in
{
  options = {
    mobile.rootfs.shared.enabled = mkOption {
      internal = true;
      type = types.bool;
      default = false;
      description = ''
        Enable when building a generic rootfs that does not include a kernel image.

        This makes sturdier rootfs that work on different devices.
      '';
    };
  };

  config = mkIf enabled {
    # Ensure we don't bring a kernel or initrd into the system.
    system.boot.loader.kernelFile = "no-kernel";
    system.boot.loader.initrdFile = "no-initrd";

    # And totally obliterate device-specific files from stage-2.
    system.extraSystemBuilderCmds = ''
      echo ":: Removing non-generic system items..."
      (
        cd $out
        rm -vf dtbs initrd kernel kernel-modules kernel-params
      )
    '';
  };
}
