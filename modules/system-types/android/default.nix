{ config, pkgs, lib, modules, baseModules, ... }:

let
  inherit (lib) concatStringsSep optionalString types;
  inherit (config.mobile) device;
  inherit (config.mobile.system.android) ab_partitions boot_as_recovery has_recovery_partition;
  inherit (config.mobile.boot) stage-1;
  kernelPackage = stage-1.kernel.package;

  enabled = config.mobile.system.type == "android";

  # In the future, this pattern should be extracted.
  # We're basically subclassing the main config, just like nesting does in
  # NixOS (<nixpkgs/modules/system/activation/top-level.nix>)
  # Here we're only adding the `is_recovery` option.
  # In the future, we may want to move the recovery configuration to a file.
  recovery = (import ../../../lib/eval-config.nix {
    inherit baseModules;
    modules = modules ++ [{
      mobile.system.android.bootimg.name = "recovery.img";
      mobile.boot.stage-1.bootConfig = {
        is_recovery = true;
      };
    }];
  }).config;

  cmdline = concatStringsSep " " config.boot.kernelParams;

  android-bootimg = pkgs.callPackage ./bootimg.nix rec {
    inherit (config.mobile.system.android) bootimg;
    inherit cmdline;
    initrd = config.system.build.initrd;
    name = "mobile-nixos_${device.name}_${bootimg.name}";
    kernel = "${kernelPackage}/${kernelPackage.file}";
  };

  android-recovery = recovery.system.build.android-bootimg;

  inherit (config.system.build) rootfs;

  # Note:
  # The flash scripts, by design, are not using nix-provided paths for
  # either of fastboot or the outputs.
  # This is because this output should have no refs. A simple tarball of this
  # output should be usable even on systems without Nix.
  # TODO: Embed device-specific fastboot instructions as `echo` in the script.
  android-device = pkgs.runCommandNoCC "android-device-${device.name}" {} ''
    mkdir -p $out
    cp -v ${rootfs}/${rootfs.filename} $out/system.img
    cp -v ${android-bootimg} $out/boot.img
    ${optionalString has_recovery_partition ''
    cp -v ${android-recovery} $out/recovery.img
    ''}
    cat > $out/flash-critical.sh <<'EOF'
    #!/usr/bin/env bash
    dir="$(cd "$(dirname "''${BASH_SOURCE[0]}")"; echo "$PWD")"
    PS4=" $ "
    set -x
    fastboot flash ${optionalString ab_partitions "--slot=all"} boot "$dir"/boot.img
    ${optionalString has_recovery_partition ''
    fastboot flash ${optionalString ab_partitions "--slot=all"} recovery "$dir"/recovery.img
    ''}
    EOF
    chmod +x $out/flash-critical.sh
  '';

  mkBootimgOption = name: lib.mkOption {
    type = types.str;
    internal = true;
  };
in
{
  options = {
    mobile.system.android = {
      ab_partitions = lib.mkOption {
        type = types.bool;
        description = "Configures whether the device uses an A/B partition scheme";
        default = false;
        internal = true;
      };

      boot_as_recovery = lib.mkOption {
        type = types.bool;
        description = "Configures whether the device uses 'boot as recovery'";
        default = config.mobile.system.android.ab_partitions;
        internal = true;
      };

      has_recovery_partition = lib.mkOption {
        type = types.bool;
        description = "Configures whether the device uses a distinct recovery partition";
        default = !config.mobile.system.android.boot_as_recovery;
        internal = true;
      };

      bootimg = {
        name = lib.mkOption {
          type = types.str;
          description = "Suffix for the image name. Use it to distinguish speciality boot images.";
          default = "boot.img";
          internal = true;
        };

        dt = lib.mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Path to a flattened device tree to pass as --dt to mkbootimg";
          internal = true;
        };

        flash = lib.attrsets.genAttrs [
          "offset_base"
          "offset_kernel"
          "offset_second"
          "offset_ramdisk"
          "offset_tags"
          "pagesize"
        ] mkBootimgOption;
      };
    };
  };

  config = lib.mkMerge [
    { mobile.system.types = [ "android" ]; }

    (lib.mkIf enabled {
      system.build = {
        default = android-device;
        inherit android-bootimg android-recovery android-device;
      };
    })

    {
      mobile.boot.stage-1.bootConfig = {
        device = {
          inherit (config.mobile.system.android) boot_as_recovery;
        };
      };
    }
  ];
}
