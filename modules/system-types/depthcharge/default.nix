{ config, pkgs, lib, ... }:

let
  enabled = config.mobile.system.type == "depthcharge";

  inherit (lib)
    concatStringsSep
    mkBefore
    mkIf
    mkMerge
    mkOption
    removeSuffix
    types
  ;
  inherit (config.mobile.outputs) stage-0;
  inherit (config.mobile.system.depthcharge.kpart) dtbs;
  deviceName = config.mobile.device.name;
  kernel = stage-0.mobile.boot.stage-1.kernel.package;
  kernel_file = "${kernel}/${if kernel ? file then kernel.file else pkgs.stdenv.hostPlatform.linux-kernel.target}";

  # Name used for some image file output.
  name = "${config.mobile.configurationName}-${deviceName}";

  # https://www.chromium.org/chromium-os/chromiumos-design-docs/disk-format
  # This doesn't fit into the generic makeGPT, some of those are really specific
  # to depthcharge.
  GPT_ENTRY_TYPES = {
    UNUSED             = "00000000-0000-0000-0000-000000000000";
    EFI                = "C12A7328-F81F-11D2-BA4B-00A0C93EC93B";
    CHROMEOS_FIRMWARE  = "CAB6E88E-ABF3-4102-A07A-D4BB9BE3C1D3";
    CHROMEOS_KERNEL    = "FE3A2A5D-4F32-41A7-B725-ACCC3285A309";
    CHROMEOS_ROOTFS    = "3CB8E202-3B7E-47DD-8A3C-7FF2A13CFCEC";
    CHROMEOS_RESERVED  = "2E0A753D-9E48-43B0-8337-B15192CB1B5E";
    LINUX_DATA         = "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7";
    LINUX_FS           = "0FC63DAF-8483-4772-8E79-3D69D8477DE4";
  };

  arch = removeSuffix "-linux" config.mobile.system.system;

  # https://github.com/thefloweringash/kevin-nix/issues/3
  make-kernel-its = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/thefloweringash/kevin-nix/a14a3bad3be7757575040b31e4c8e1bb801a8ed3/modules/make-kernel-its.sh";
    sha256 = "1c0zbk69lyd3n8a636njc6in174zccg3hpjmafhxvfmyf45vxjis";
  };

  # Kernel command line for vbutil_kernel.
  kpart_config = pkgs.writeTextFile {
    name = "kpart-config-${deviceName}";
    text = concatStringsSep " " config.boot.kernelParams;
  };

  # The image file containing the kernel and initrd.
  kpart = pkgs.runCommand "kpart-${name}" {
    nativeBuildInputs = with pkgs; [
      dtc
      ubootTools
      vboot_reference
      xz
    ];
  } ''
    # Bootloader
    dd if=/dev/zero of=bootloader.bin bs=512 count=1

    # Kernel
    lzma --threads 0 < ${kernel_file} > kernel.lzma

    ln -s ${dtbs} dtbs
    ln -s ${stage-0.mobile.outputs.initrd} initrd

    bash ${make-kernel-its} $PWD > kernel.its

    mkimage \
      -D "-I dts -O dtb -p 2048" \
      -f kernel.its \
      vmlinux.uimg

    futility vbutil_kernel \
      --version 1 \
      --bootloader bootloader.bin \
      --vmlinuz vmlinux.uimg \
      --arch ${arch} \
      --keyblock ${pkgs.vboot_reference}/share/vboot/devkeys/kernel.keyblock \
      --signprivate ${pkgs.vboot_reference}/share/vboot/devkeys/kernel_data_key.vbprivk \
      --config ${kpart_config} \
      --pack $out
  '';
in
{
  options = {
    mobile.system.depthcharge = {
      kpart = {
        dtbs = mkOption {
          type = types.path;
          default = null;
          description = "Path to a directory with device trees, to be put in the kpart image";
          internal = true;
        };
      };
    };
    mobile = {
      outputs = {
        depthcharge = {
          disk-image = mkOption {
            type = types.package;
            description = ''
              Full Mobile NixOS disk image for a depthcharge-based system.
            '';
            visible = false;
          };
          kpart = mkOption {
            type = types.package;
            description = ''
              Kernel partition for a depthcharge-based system.
            '';
            visible = false;
          };
        };
      };
    };
  };

  config = mkMerge [
    { mobile.system.types = [ "depthcharge" ]; }

    (mkIf enabled {
      mobile.generatedDiskImages.disk-image = {
        partitions = mkBefore [
          {
            name = "kernel";
            raw = kpart;
            partitionLabel = "KERNEL-A";
            partitionType = GPT_ENTRY_TYPES.CHROMEOS_KERNEL;
            length = pkgs.image-builder.helpers.size.MiB 128;
          }
        ];

        # Add the missing bits to the kernel partition for depthcharge.
        additionalCommands = ''
          echo ":: Making image bootable by depthcharge"
          (PS4=" $ "; set -x
          ${pkgs.buildPackages.vboot_reference}/bin/cgpt ${concatStringsSep " " [
            "add"
            "-i 1"  # Work on the first partition (instead of adding)
            "-S 1"  # Mark as successful (so it'll be booted from)
            "-T 5"  # Tries remaining
            "-P 10" # Priority
            "$img"
          ]}
          ${pkgs.buildPackages.vboot_reference}/bin/cgpt ${concatStringsSep " " [
            "show"
            "$img"
          ]}
          )
        '';
      };
      mobile.outputs = {
        default = config.mobile.outputs.depthcharge.disk-image;
        depthcharge = {
          inherit kpart;
          disk-image = config.mobile.generatedDiskImages.disk-image.output;
        };
      };
    })
  ];
}
