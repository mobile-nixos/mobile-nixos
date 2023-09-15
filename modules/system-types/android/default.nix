{ config, pkgs, lib, modules, baseModules, ... }:

let
  enabled = config.mobile.system.type == "android";

  inherit (lib) concatStringsSep optionalString types;
  inherit (config.mobile.outputs) recovery stage-0;
  inherit (config.mobile) device;
  inherit (config.mobile.system.android) ab_partitions boot_as_recovery has_recovery_partition flashingMethod;
  inherit (stage-0.mobile.boot.stage-1) kernel;

  kernelPackage = kernel.package;

  cmdline = concatStringsSep " " config.boot.kernelParams;

  android-bootimg = pkgs.callPackage ./bootimg.nix rec {
    inherit (config.mobile.system.android) bootimg;
    inherit cmdline;
    inherit (config.mobile.outputs) initrd;
    name = "mobile-nixos_${device.name}_${bootimg.name}";
    kernel = "${kernelPackage}/${kernelPackage.file}";
    inherit (config.mobile.system.android) appendDTB;
  };

  android-recovery = recovery.mobile.outputs.android.android-bootimg;

  inherit (config.mobile.generatedFilesystems) rootfs;

  # Note:
  # The flash scripts, by design, are not using nix-provided paths for
  # either of fastboot or the outputs.
  # This is because this output should have no refs. A simple tarball of this
  # output should be usable even on systems without Nix.
  android-fastboot-images = pkgs.runCommand "android-fastboot-images-${device.name}" {} ''
    mkdir -p $out
    cp -v ${rootfs.imagePath} $out/system.img
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
    else if flashingMethod == "lk2nd" then ''
      echo "There is no automated script for flashing with lk2nd yet."
      echo "Please refer to the installation instructions for your device."
      exit 1
    ''
    else builtins.throw "No flashing method for ${flashingMethod}"})
    echo ""
    echo "Flashing completed."
    echo "The system image needs to be flashed manually to the ${config.mobile.system.android.system_partition_destination} partition."
    EOF
    chmod +x $out/flash-critical.sh
  '';

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
        description = lib.mdDoc "Configures whether the device uses an A/B partition scheme";
        default = false;
        internal = true;
      };

      boot_as_recovery = lib.mkOption {
        type = types.bool;
        description = lib.mdDoc "Configures whether the device uses 'boot as recovery'";
        default = config.mobile.system.android.ab_partitions;
        internal = true;
      };

      device_name = lib.mkOption {
        type = types.nullOr types.str;
        description = lib.mdDoc "Value of `ro.product.device` or `ro.build.product`. Used to compare against in flashable zips.";
        default = null;
        internal = true;
      };

      flashingMethod = lib.mkOption {
        type = types.enum [
          "fastboot" # Default, using `fastboot`
          "lk2nd"    # Some Qualcomm mainline devices, using fastboot and lk2nd
          "odin"     # Mainly Samsung, using `heimdall`
        ];
        description = lib.mdDoc "Configures which flashing method is used by the device.";
        default = "fastboot";
        internal = true;
      };

      has_recovery_partition = lib.mkOption {
        type = types.bool;
        description = lib.mdDoc "Configures whether the device uses a distinct recovery partition";
        default = !config.mobile.system.android.boot_as_recovery;
        internal = true;
      };

      boot_partition_destination = lib.mkOption {
        type = types.str;
        description = lib.mdDoc "Partition label on which to install the boot image. Some OEM name the partition BOOT.";
        default = "boot";
        internal = true;
      };

      system_partition_destination = lib.mkOption {
        type = types.str;
        description = lib.mdDoc "Partition label on which to install the system image. E.g. change to `userdata` when it does not fit in the system partition.";
        default = "system";
        internal = true;
      };

      bootimg = {
        name = lib.mkOption {
          type = types.str;
          description = lib.mdDoc "Suffix for the image name. Use it to distinguish speciality boot images.";
          default = "boot.img";
          internal = true;
        };

        dt = lib.mkOption {
          type = types.nullOr types.path;
          default = null;
          description = lib.mdDoc "Path to a flattened device tree to pass as --dt to mkbootimg";
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

      appendDTB = lib.mkOption {
        type = with types; nullOr (listOf (oneOf [path str]));
        default = null;
        description = lib.mdDoc "List of dtb files to append to the kernel, when device uses appended DTB.";
      };
    };
    mobile = {
      outputs = {
        android = {
          android-bootimg = lib.mkOption {
            type = types.package;
            description = lib.mdDoc ''
              `boot.img` type image for Android-based systems.
            '';
            visible = false;
          };
          android-recovery = lib.mkOption {
            type = types.package;
            description = lib.mdDoc ''
              `recovery.img` type image for Android-based systems.
            '';
            visible = false;
          };
          android-fastboot-images = lib.mkOption {
            type = types.package;
            description = lib.mdDoc ''
              Flashing scripts and images for use with fastboot or odin.
            '';
            visible = false;
          };
        };
      };
    };
  };

  config = lib.mkMerge [
    { mobile.system.types = [ "android" ]; }

    (lib.mkIf enabled {
      mobile.outputs = {
        default = android-fastboot-images;
        android = {
          inherit
            android-bootimg
            android-recovery
            android-fastboot-images
          ;
        };
      };

      mobile.HAL.boot.rebootModes = [
        "Android.recovery"
        "Android.bootloader"
      ];

      mobile.documentation.systemTypeFargment = ./. + "/device-notes.${flashingMethod}.adoc.erb";

      assertions = [
        {
          assertion = config.mobile.system.android.appendDTB == null || config.mobile.system.android.bootimg.dt == null;
          message = ''
            Device configuration erroneous: `mobile.android.appendDTB` and legacy `bootimg.dt` enabled.
              Tip: enabling `isQcdt` or `isExynosDT` on your kernel is not needed qhen using `appendDTB`.
          '';
        }
      ];
    })

    (lib.mkIf (kernelPackage != null && kernelPackage.isQcdt) {
      mobile.system.android.bootimg.dt = "${kernelPackage}/dt.img";
    })

    (lib.mkIf (kernelPackage != null && kernelPackage.isExynosDT) {
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
