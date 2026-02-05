{ config, pkgs, lib, ... }:

let
  inherit (lib)
    mkIf
    mkOption
    mkEnableOption
    types
  ;

  cfg = config.mobile.boot.stage-1.microhop;
  device = config.mobile.device;
  stage-1 = config.mobile.boot.stage-1;

  # Only include modules if kernel is modular
  kernelIsModular = stage-1.kernel.package.isModular or true;
  effectiveModules = if kernelIsModular then cfg.modules else [];

  microhopConfig = pkgs.writeText "microhop-${device.name}.conf" ''
# Microhop configuration for ${device.name}

# Kernel modules to load
modules:
${lib.concatMapStringsSep "\n" (mod: "  - ${mod}") effectiveModules}

# Mount configuration
# Format: key: "fstype,mountpoint,mode"
disks:
${lib.concatStringsSep "\n" (map (disk:
  let
    parts = lib.splitString ": " disk;
    key = builtins.head parts;
    value = lib.concatStringsSep ": " (lib.tail parts);
  in
    "  ${key}: \"${value}\""
) cfg.disks)}

# Execute systemd/init after switching root
init: ${cfg.init}

# Temporary sysroot location
sysroot: ${cfg.sysroot}

# Log level: debug, info, quiet
log: ${cfg.logLevel}

# NixOS configuration
# Enable NixOS store registration before switch_root
nixos:
  nix_path: ${config.nix.package}
${lib.optionalString (cfg.overlayDevice != null) ''
# Overlayfs configuration
overlay_dev: ${cfg.overlayDevice}
''}
${lib.optionalString (builtins.length cfg.mask_cmdline > 0) ''
# Mask kernel cmdline parameters (ignore these from bootloader)
mask_cmdline:
${lib.concatMapStringsSep "\n" (param: "  - ${param}") cfg.mask_cmdline}
''}
  '';

  firmwareListFile =
    let
      extractPath = fwFile:
        builtins.head (builtins.match ".*/lib/firmware/(.*)" (toString fwFile));
    in
      pkgs.writeText "firmware-list.txt" (
        lib.concatMapStringsSep "\n"
          (fwFile: "${fwFile}:${extractPath fwFile}")
          cfg.firmwareFiles
      );

  initrd = pkgs.stdenv.mkDerivation {
    name = "initramfs-microhop-${device.name}";

    nativeBuildInputs = with pkgs; [
      config.mobile.boot.stage-1.microhop.microhop
      cpio
      gzip
      xz
      findutils
      kmod  # For depmod to generate module dependencies
    ];

    unpackPhase = "true";

    buildPhase = ''
      echo "Validating microhop configuration..."
      if ! ${cfg.microhop}/bin/microgen validate --config ${microhopConfig} 2>&1; then
        echo "ERROR: Configuration validation failed!"
        exit 1
      fi

      mkdir -p $TMPDIR/rootfs/lib/modules
      
      ${lib.optionalString (stage-1.kernel.package != null && kernelIsModular) ''
        if [ -d "${stage-1.kernel.package}/lib/modules" ] && [ -n "$(ls -A ${stage-1.kernel.package}/lib/modules 2>/dev/null)" ]; then
          echo "Copying kernel modules..."
          cp -r ${stage-1.kernel.package}/lib/modules/* $TMPDIR/rootfs/lib/modules/
          chmod -R u+w $TMPDIR/rootfs/lib/modules/

          # Detect kernel version ONCE
          KERNEL_VERSION=$(ls $TMPDIR/rootfs/lib/modules/ | head -1)

          # Copy kernel config
          if [ -f "${stage-1.kernel.package}/.config" ]; then
            install -D -m644 "${stage-1.kernel.package}/.config" \
              "$TMPDIR/rootfs/lib/modules/$KERNEL_VERSION/build/.config"
          fi
          
          # Generate module dependencies
          echo "Generating module metadata..."
          depmod -b $TMPDIR/rootfs "$KERNEL_VERSION"
        fi
      ''}
      
      ${lib.optionalString (cfg.firmwareFiles != []) ''
        echo "Setting up firmware..."
        ${lib.concatMapStringsSep "\n" (fwFile: 
          let 
            relativePath = builtins.head (builtins.match ".*/lib/firmware/(.*)" (toString fwFile));
          in ''
            install -D -m644 "${fwFile}" "$TMPDIR/rootfs/lib/firmware/${relativePath}"
          ''
        ) cfg.firmwareFiles}

        cp ${firmwareListFile} "$TMPDIR/firmware-list.txt"
      ''}

      echo "Generating initramfs with microgen..."

      MICROGEN_CMD="${cfg.microhop}/bin/microgen new \
        --root $TMPDIR/rootfs \
        --config ${microhopConfig} \
        --output $TMPDIR/initramfs-build \
        --file $TMPDIR/initrd"

      ${lib.optionalString (cfg.firmwareFiles != []) ''
        MICROGEN_CMD="$MICROGEN_CMD --firmware-list $TMPDIR/firmware-list.txt"
      ''}

      eval "$MICROGEN_CMD"

      [ -f "$TMPDIR/initrd" ] || { echo "ERROR: microgen failed"; exit 1; }
      install -D -m644 "$TMPDIR/initrd" "$out"
    '';

    installPhase = "true";
  };
in
{
  options.mobile.boot.stage-1.microhop = {
    enable = mkEnableOption "microhop initramfs" // {
      description = ''
        Use microhop Rust-based initramfs instead of the default Mobile NixOS Ruby-based init.

        Microhop provides a minimal, fast, single-binary init system suitable for
        embedded and mobile devices.
      '';
    };

    microhop = mkOption {
      type = types.package;
      description = ''
        The microgen package to use for generating the initramfs.
        This should come from the microhop flake input.
      '';
    };

    modules = mkOption {
      type = types.listOf types.str;
      default = if (stage-1 ? kernel && stage-1.kernel ? modules && stage-1.kernel.modules != null)
                then stage-1.kernel.modules
                else [];
      description = ''
        List of kernel modules to load in initramfs.
        Defaults to the modules specified in stage-1.kernel.modules.
      '';
    };

    disks = mkOption {
      type = types.listOf types.str;
      default = [ "/dev/sda21: ext4,/,rw" ];
      description = ''
        Disk mount configuration in microhop format.
        Each entry should be in format:
        - "label=LABELNAME: fstype,mountpoint,options"
        - "uuid=UUID: fstype,mountpoint,options"
        - "/dev/device: fstype,mountpoint,options"

        Note: label= and uuid= prefixes are preferred over plain labels/UUIDs.
      '';
      example = [
        "label=NIXOS_ROOT: ext4,/,rw"
        "uuid=24e1daee-e09b-4fd5-97f3-dde8aba6ad8a: ext4,/,rw"
        "/dev/mmcblk0p1: vfat,/boot,ro"
      ];
    };

    filesystems = mkOption {
      type = types.listOf types.str;
      default = [ "ext4" ];
      description = ''
        List of filesystem types to support.
      '';
    };

    blockDevices = mkOption {
      type = types.listOf types.str;
      #default = [ "sdhci" "ufshcd" ];
      description = ''
        List of block device drivers to support.
      '';
    };

    init = mkOption {
      type = types.str;
      default = "/sbin/init";
      description = ''
        Path to init binary to execute after switching root.
      '';
    };

    sysroot = mkOption {
      type = types.str;
      default = "/sysroot";
      description = ''
        Temporary sysroot mount point.
      '';
    };

    logLevel = mkOption {
      type = types.enum [ "debug" "info" "quiet" ];
      default = "info";
      description = ''
        Log level for microhop init.
      '';
    };

    overlayDevice = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Device to use for overlayfs upper/work directories.
        If null, no overlayfs is used.
      '';
      example = "/dev/mmcblk0p2";
    };

    firmwareFiles = mkOption {
      type = types.listOf types.path;
      default = [];
      description = ''
        List of specific firmware files to copy to the initramfs.
        Each file will be copied to /lib/firmware in the initramfs.
        The build will fail if any of the specified files is missing.

        Use this for device-specific firmware that must be present
        in the initramfs for the device to boot properly.
      '';
        example = lib.literalExpression ''
        [
          "''${pkgs.linux-firmware.zstd}/lib/firmware/qcom/sdm845/adsp.mdt.zstd"
          "''${device.firmware}/lib/firmware/a630_gmu.bin"
        ]
      '';
    };

    mask_cmdline = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        List of kernel cmdline parameter names to mask/ignore.

        This is useful when the bootloader passes parameters that conflict
        with your desired configuration. Microhop will ignore these parameters
        from the kernel cmdline and use the values from the config file instead.

        Common use case: Android bootloaders often pass a hardcoded PARTUUID
        that doesn't match the actual filesystem. Use mask_cmdline = ["root"]
        to ignore the bootloader's root parameter and use the disk configuration
        from the microhop config instead.
      '';
      example = [ "root" "init" ];
    };
  };

  config = mkIf cfg.enable {
    # Disable the default Mobile NixOS stage-1
    mobile.boot.stage-1.enable = false;

    # Disable NixOS default initrd
    boot.initrd.enable = false;

    # Override the initrd output - the derivation now produces the initrd file
    mobile.outputs.initrd = initrd;

    system.build.initialRamdisk = initrd;
  };
}
