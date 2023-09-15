{ config, pkgs, lib, modules, baseModules, ... }:

let
  enabled = config.mobile.system.type == "uefi";

  inherit (lib) mkBefore mkEnableOption mkIf mkOption types;
  inherit (pkgs.stdenv) hostPlatform;
  inherit (pkgs) image-builder runCommand;
  inherit (config.mobile.outputs) recovery stage-0;
  deviceName = config.mobile.device.name;
  kernel = stage-0.mobile.boot.stage-1.kernel.package;
  kernelFile = "${kernel}/${if kernel ? file then kernel.file else pkgs.stdenv.hostPlatform.linux-kernel.target}";
  inherit (config.mobile.generatedFilesystems) rootfs;
  boot-partition = config.mobile.generatedFilesystems.boot.output;

  # Look-up table to translate from targetPlatform to U-Boot names.
  uefiPlatforms = {
    "i686-linux"    = "ia32";
    "x86_64-linux"  =  "x64";
    "aarch64-linux" = "aa64";
  };
  uefiPlatform = uefiPlatforms.${pkgs.stdenv.targetPlatform.system};

  efiKernel = pkgs.runCommand "${deviceName}-efiKernel" {
    kernelParamsFile = pkgs.writeText "${deviceName}-boot.cmd" config.boot.kernelParams;
    nativeBuildInputs = [
      pkgs.stdenv.cc.bintools.bintools_bin
    ];
  } ''
    (PS4=" $ "; set -x
    ${pkgs.stdenv.cc.bintools.targetPrefix}objcopy \
      --add-section .cmdline="$kernelParamsFile"              --change-section-vma  .cmdline=0x30000 \
      --add-section .linux="${kernelFile}"                    --change-section-vma  .linux=0x2000000 \
      --add-section .initrd="${config.mobile.outputs.initrd}" --change-section-vma .initrd=0x3000000 \
      "${pkgs.udev}/lib/systemd/boot/efi/linux${uefiPlatform}.efi.stub" \
      "$out"
    )
  '';
in
{
  imports = [
    ./vm.nix
  ];

  options.mobile = {
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
      mobile.generatedDiskImages.disk-image = {
        partitions = mkBefore [
          (pkgs.image-builder.helpers.makeESP {
            name = "mn-ESP"; # volume name (up to 11 characters long)
            partitionLabel = "mn-ESP";
            partitionUUID = "CFB21B5C-A580-DE40-940F-B9644B4466E2";
            raw = boot-partition;
          })
        ];
      };
      mobile.generatedFilesystems.boot = {
        filesystem = "fat32";
        # Let's give us a *bunch* of space to play around.
        # And let's not forget we have the kernel and stage-1 twice.
        size = pkgs.image-builder.helpers.size.MiB 128;

        fat32.partitionID = "4E021684";
        populateCommands = ''
          mkdir -p EFI/boot
          cp ${stage-0.mobile.outputs.uefi.efiKernel}  EFI/boot/boot${uefiPlatform}.efi
          cp ${recovery.mobile.outputs.uefi.efiKernel} EFI/boot/recovery${uefiPlatform}.efi
        '';
      };
      mobile.outputs = {
        default = config.mobile.outputs.uefi.disk-image;
        uefi = {
          inherit efiKernel;
          inherit boot-partition;
          disk-image = config.mobile.generatedDiskImages.disk-image.output;
        };
      };
    })
  ];
}
