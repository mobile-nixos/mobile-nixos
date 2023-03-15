{ config, pkgs, lib, modules, baseModules, ... }:

let
  enabled = config.mobile.system.type == "uefi";

  inherit (lib) mkEnableOption mkIf mkOption types;
  inherit (pkgs.stdenv) hostPlatform;
  inherit (pkgs) imageBuilder runCommand;
  inherit (config.mobile.outputs) recovery stage-0;
  cfg = config.mobile.quirks.uefi;
  deviceName = config.mobile.device.name;
  kernel = stage-0.mobile.boot.stage-1.kernel.package;
  kernelFile = "${kernel}/${if kernel ? file then kernel.file else pkgs.stdenv.hostPlatform.linux-kernel.target}";

  # Look-up table to translate from targetPlatform to U-Boot names.
  uefiPlatforms = {
    "i686-linux"    = "ia32";
    "x86_64-linux"  =  "x64";
    "aarch64-linux" = "aa64";
  };
  uefiPlatform = uefiPlatforms.${pkgs.stdenv.targetPlatform.system};

  kernelParamsFile = pkgs.writeText "${deviceName}-boot.cmd" config.boot.kernelParams;

  efiKernel = pkgs.runCommand "${deviceName}-efiKernel" {
    nativeBuildInputs = [
      pkgs.stdenv.cc.bintools.bintools_bin
    ];
  } ''
    (PS4=" $ "; set -x
    ${pkgs.stdenv.cc.bintools.targetPrefix}objcopy \
      --add-section .cmdline="${kernelParamsFile}"            --change-section-vma  .cmdline=0x30000 \
      --add-section .linux="${kernelFile}"                    --change-section-vma  .linux=0x2000000 \
      --add-section .initrd="${config.mobile.outputs.initrd}" --change-section-vma .initrd=0x3000000 \
      "${pkgs.udev}/lib/systemd/boot/efi/linux${uefiPlatform}.efi.stub" \
      "$out"
    )
  '';

  # TODO: use generatedFilesystems
  boot-partition =
    imageBuilder.fileSystem.makeESP {
      name = "mn-ESP"; # volume name (up to 11 characters long)
      partitionLabel = "mn-ESP";
      partitionID   = "4E021684"; # FIXME: forwarded to filesystem volume ID, it shouldn't be
      partitionUUID = "CFB21B5C-A580-DE40-940F-B9644B4466E2";

      # Let's give us a *bunch* of space to play around.
      # And let's not forget we have the kernel and stage-1 twice.
      size = imageBuilder.size.MiB 128;

      populateCommands = ''
        mkdir -p EFI/boot
        cp ${stage-0.mobile.outputs.uefi.efiKernel}  EFI/boot/boot${uefiPlatform}.efi
        cp ${recovery.mobile.outputs.uefi.efiKernel} EFI/boot/recovery${uefiPlatform}.efi
      '';
    }
  ;

  miscPartition = {
    # Used as a BCB.
    name = "misc";
    partitionLabel = "misc";
    partitionUUID = "5A7FA69C-9394-8144-A74C-6726048B129D";
    length = imageBuilder.size.MiB 1;
    partitionType = "EF32A33B-A409-486C-9141-9FFB711F6266";
    filename = "/dev/null";
  };

  persistPartition = imageBuilder.fileSystem.makeExt4 {
    # To work more like Android-based systems.
    name = "persist";
    partitionLabel = "persist";
    partitionID = "5553F4AD-53E1-2645-94BA-2AFC60C12D38";
    partitionUUID = "5553F4AD-53E1-2645-94BA-2AFC60C12D39";
    size = imageBuilder.size.MiB 16;
    partitionType = "EBC597D0-2053-4B15-8B64-E0AAC75F4DB1";
  };

  disk-image = imageBuilder.diskImage.makeGPT {
    name = "mobile-nixos";
    diskID = "01234567";
    headerHole = cfg.initialGapSize;
    partitions = [
      boot-partition
      miscPartition
      persistPartition
      config.mobile.outputs.generatedFilesystems.rootfs
    ];
  };
in
{
  imports = [
    ./vm.nix
  ];

  options.mobile = {
    quirks.uefi = {
      initialGapSize = mkOption {
        type = types.int;
        default = 0;
        description = lib.mdDoc ''
          Size (in bytes) to keep reserved in front of the first partition.
        '';
      };
    };

    outputs = {
      uefi = {
        boot-partition = mkOption {
          type = types.package;
          description = lib.mdDoc ''
            Boot partition for the system.
          '';
          visible = false;
        };
        disk-image = lib.mkOption {
          type = types.package;
          description = lib.mdDoc ''
            Full Mobile NixOS disk image for a UEFI-based system.
          '';
          visible = false;
        };
        efiKernel = mkOption {
          type = types.package;
          description = lib.mdDoc ''
            EFI executable with the kernel, cmdline and initramfs built-in.
          '';
          visible = false;
        };
      };
    };
  };

  config = lib.mkMerge [
    { mobile.system.types = [ "uefi" ]; }
    (mkIf enabled {
      mobile.outputs = {
        default = config.mobile.outputs.uefi.disk-image;
        uefi = {
          inherit efiKernel;
          inherit boot-partition;
          inherit disk-image;
        };
      };
    })
  ];
}
