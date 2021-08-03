{ config, pkgs, lib, modules, baseModules, ... }:

let
  enabled = config.mobile.system.type == "android";

  inherit (lib) concatStringsSep optionalString types;
  inherit (config.system.build) recovery stage-0;
  inherit (config.mobile) device;
  inherit (config.mobile.system.android) ab_partitions boot_as_recovery has_recovery_partition flashingMethod;
  inherit (stage-0.mobile.boot.stage-1) kernel;

  kernelPackage = kernel.package;

  cmdline = concatStringsSep " " config.boot.kernelParams;

  android-bootimg = pkgs.callPackage ./bootimg.nix rec {
    inherit (config.mobile.system.android) bootimg;
    inherit cmdline;
    initrd = stage-0.system.build.initrd;
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
  android-fastboot-images = pkgs.runCommandNoCC "android-fastboot-images-${device.name}" {} ''
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
    ${if has_recovery_partition then ''
    echo "NOTE: This script flashes the boot and recovery partitions only."
    '' else ''
    echo "NOTE: This script flashes the boot partition only."
    ''}
    (
    set -x
    ${if flashingMethod == "fastboot" then ''
      fastboot flash ${optionalString ab_partitions "--slot=all"} boot "$dir"/boot.img
      ${optionalString has_recovery_partition ''
      fastboot flash ${optionalString ab_partitions "--slot=all"} recovery "$dir"/recovery.img
      ''}
    ''
    else if flashingMethod == "odin" then ''
      heimdall flash \
        --BOOT "$dir"/boot.img ${optionalString has_recovery_partition ''\
        --RECOVERY "$dir"/recovery.img
      ''}
    ''
    else builtins.throw "No flashing method for ${flashingMethod}"})
    echo ""
    echo "Flashing completed."
    echo "The system image needs to be flashed manually to the ${config.mobile.system.android.system_partition_destination} partition."
    EOF
    chmod +x $out/flash-critical.sh
  '';

  # The output name `android-device` does not describe well what it is.
  # This is kept for some backwards compatibility (6 months)
  # Change to a throw by or after September 2021.
  android-device = builtins.trace "The output `android-device` has been renamed to: `android-systems-image`." android-fastboot-images;

  mkBootimgOption = name: lib.mkOption {
    type = types.str;
    internal = true;
  };
in
{
  imports = [
    ./flashable-zip.nix
  ];

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

      device_name = lib.mkOption {
        type = types.nullOr types.str;
        description = "Value of `ro.product.device` or `ro.build.product`. Used to compare against in flashable zips.";
        default = null;
        internal = true;
      };

      flashingMethod = lib.mkOption {
        type = types.enum [
          "fastboot" # Default, using `fastboot`
          "odin"     # Mainly Samsung, using `heimdall`
        ];
        description = "Configures which flashing method is used by the device.";
        default = "fastboot";
        internal = true;
      };

      has_recovery_partition = lib.mkOption {
        type = types.bool;
        description = "Configures whether the device uses a distinct recovery partition";
        default = !config.mobile.system.android.boot_as_recovery;
        internal = true;
      };

      boot_partition_destination = lib.mkOption {
        type = types.str;
        description = "Partition label on which to install the boot image. Some OEM name the partition BOOT.";
        default = "boot";
        internal = true;
      };

      system_partition_destination = lib.mkOption {
        type = types.str;
        description = "Partition label on which to install the system image. E.g. change to `userdata` when it does not fit in the system partition.";
        default = "system";
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
        default = android-fastboot-images;
        inherit
          android-device
          android-bootimg
          android-recovery
          android-fastboot-images
        ;
      };

      mobile.HAL.boot.rebootModes = [
        "Android.recovery"
        "Android.bootloader"
      ];

      mobile.documentation.systemTypeFargment = ./. + "/device-notes.${flashingMethod}.adoc.erb";
    })

    (lib.mkIf kernelPackage.isQcdt {
      mobile.system.android.bootimg.dt = "${kernelPackage}/dt.img";
    })

    (lib.mkIf kernelPackage.isExynosDT {
      mobile.system.android.bootimg.dt = "${kernelPackage}/dt.img";
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
