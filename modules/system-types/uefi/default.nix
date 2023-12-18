{ config, pkgs, lib, modules, baseModules, ... }:

let
  enabled = config.mobile.system.type == "uefi";

  inherit (lib) mkBefore mkIf mkOption types;
  inherit (config.mobile.outputs) recovery stage-0;
  deviceName = config.mobile.device.name;
  kernel = stage-0.mobile.boot.stage-1.kernel.package;
  kernelFile = "${kernel}/${if kernel ? file then kernel.file else pkgs.stdenv.hostPlatform.linux-kernel.target}";
  boot-partition = config.mobile.generatedFilesystems.boot.output;

  # Look-up table to translate from targetPlatform to U-Boot names.
  uefiPlatforms = {
    "i686-linux"    = "ia32";
    "x86_64-linux"  =  "x64";
    "aarch64-linux" = "aa64";
  };
  uefiPlatform = uefiPlatforms.${pkgs.stdenv.targetPlatform.system};

  efiKernel = pkgs.runCommand "${deviceName}-efiKernel" {
    osReleaseFile = pkgs.writeText "${deviceName}-osrel.cmd" config.environment.etc."os-release".source;
    kernelParamsFile = pkgs.writeText "${deviceName}-boot.cmd" config.boot.kernelParams;
    systemdStub = "${pkgs.systemd}/lib/systemd/boot/efi/linux${uefiPlatform}.efi.stub";
    nativeBuildInputs = [
      pkgs.stdenv.cc.bintools.bintools_bin
    ];
  } ''
    PS4=" $ "

    # Add a section to the systemd EFI stub, following its implied semantics.
    add_section() {
      output="$1"; shift
      name="$1"; shift
      section="$1"; shift

      SectionAlignment=0x$(
        ${pkgs.stdenv.cc.bintools.targetPrefix}objdump \
          --private-headers "$output" \
          | grep SectionAlignment \
          | cut -f2
      )
      set $(
        ${pkgs.stdenv.cc.bintools.targetPrefix}objdump \
          --headers "$output" \
          | grep '^\s\+[0-9]\+\s\+\.' \
          | sort -k 4 \
          | tail -n1
      )

      # Tail end location of the last section
      tail=$(( 0x$3 + 0x$4 ))

      # The new section's start is then aligned with SectionAlignment
      new_section_offset=$(( tail + SectionAlignment - tail % SectionAlignment ))

      # We're modifying "in-place" (which is a lie).
      mv $output $output.tmp
      (set -x
      ${pkgs.stdenv.cc.bintools.targetPrefix}objcopy \
        --add-section "$name"="$section" --change-section-vma "$name"="$new_section_offset" \
        "$output.tmp" "$output"
      )
      # So since we lied, remove the temporary file.
      rm $output.tmp
    }

    # Cheekily copy the file without keeping its mode.
    cat $systemdStub > stub

    add_section "stub" ".osrel"   "$osReleaseFile"
    add_section "stub" ".cmdline" "$kernelParamsFile"
    add_section "stub" ".initrd"  "${config.mobile.outputs.initrd}"
    add_section "stub" ".linux"   "${kernelFile}"

    mv stub $out

    # Let's print what we did at the end, might be helpful.
    (set -x
    ${pkgs.stdenv.cc.bintools.targetPrefix}objdump \
      --headers "$out"
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
