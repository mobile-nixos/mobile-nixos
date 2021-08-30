{ config, pkgs, lib, modules, baseModules, ... }:

let
  enabled = config.mobile.system.type == "u-boot";

  inherit (config.mobile.outputs) recovery stage-0;
  inherit (pkgs) buildPackages imageBuilder runCommandNoCC;
  inherit (lib) mkIf mkOption types;
  cfg = config.mobile.quirks.u-boot;
  inherit (cfg) soc;
  deviceName = config.mobile.device.name;
  kernel = stage-0.mobile.boot.stage-1.kernel.package;
  kernel_file = "${kernel}/${kernel.file}";

  # Look-up table to translate from targetPlatform to U-Boot names.
  ubootPlatforms = {
    "aarch64-linux" = "arm64";
  };

  bootcmd = pkgs.writeText "${deviceName}-boot.cmd" ''
    echo ****************
    echo * Mobile NixOS *
    echo ****************
    echo
    echo Built for ${deviceName}
    echo

    setenv bootargs ${lib.concatStringsSep " " config.boot.kernelParams}

    ${cfg.additionalCommands}

    echo
    echo === debug information ===
    printenv bootargs
    echo
    printenv kernel_addr_r
    printenv fdt_addr_r
    printenv ramdisk_addr_r
    echo === end of the debug information ===
    echo

    if test "$mmc_bootdev" != ""; then
      echo ":: Detected mmc booting"
      devtype="mmc"
    else
      echo "!!! Could not detect devtype !!!"
      exit
    fi

    if test "$devtype" = "mmc"; then
      devnum="$mmc_bootdev"
      echo ":: Booting from mmc $devnum"
    fi

    bootpart=""
    echo part number $devtype $devnum boot bootpart
    part number $devtype $devnum boot bootpart
    echo $bootpart

    # To stay compatible with the previous scheme, and more importantly, the
    # default assumptions from U-Boot, detect the bootable legacy flag.
    if test "$bootpart" = ""; then
      echo "Could not find a partition with the partlabel 'boot'."
      echo "(looking at partitions marked bootable)"
      part list ''${devtype} ''${devnum} -bootable bootpart
      # This may print out an error message when there is only one result.
      # Though it still is fine.
      setexpr bootpart gsub ' .*' "" "$bootpart"
    fi

    if test "$bootpart" = ""; then
      echo "!!! Could not find 'boot' partition on $devtype $devnum !!!"
      exit
    fi

    echo ":: Booting from partition $bootpart"

    if load ''${devtype} ''${devnum}:''${bootpart} ''${kernel_addr_r} /mobile-nixos/boot/kernel; then
      setenv boot_type boot
    else
      if load ''${devtype} ''${devnum}:''${bootpart} ''${kernel_addr_r} /mobile-nixos/recovery/kernel; then
        setenv boot_type recovery
        setenv bootargs ''${bootargs} is_recovery
      else
        echo "!!! Failed to load either of the normal and recovery kernels !!!"
        exit
      fi
    fi

    if load ''${devtype} ''${devnum}:''${bootpart} ''${fdt_addr_r} /mobile-nixos/''${boot_type}/dtbs/''${fdtfile}; then
      fdt addr ''${fdt_addr_r}
      fdt resize
    fi

    load ''${devtype} ''${devnum}:''${bootpart} ''${ramdisk_addr_r} /mobile-nixos/''${boot_type}/stage-1
    setenv ramdisk_size ''${filesize}

    echo bootargs: ''${bootargs}
    echo booti ''${kernel_addr_r} ''${ramdisk_addr_r}:''${ramdisk_size} ''${fdt_addr_r};

    booti ''${kernel_addr_r} ''${ramdisk_addr_r}:''${ramdisk_size} ''${fdt_addr_r};
  '';

  bootscr = runCommandNoCC "${deviceName}-boot.scr" {
    nativeBuildInputs = [
      buildPackages.ubootTools
    ];
  } ''
    mkimage -C none -A ${ubootPlatforms.${pkgs.targetPlatform.system}} -T script -d ${bootcmd} $out
  '';

  # TODO: use generatedFilesystems
  boot-partition =
    imageBuilder.fileSystem.makeExt4 {
      name = "mobile-nixos-boot";
      partitionLabel = "boot";
      partitionID = "ED3902B6-920A-4971-BC07-966D4E021683";
      partitionUUID = "CFB21B5C-A580-DE40-940F-B9644B4466E1";
      # Let's give us a *bunch* of space to play around.
      # And let's not forget we have the kernel and stage-1 twice.
      size = imageBuilder.size.MiB 128;
      bootable = true;
      populateCommands = ''
        mkdir -vp mobile-nixos/{boot,recovery}
        (
        cd mobile-nixos/boot
        cp -v ${stage-0.mobile.outputs.initrd} stage-1
        cp -v ${kernel_file} kernel
        cp -vr ${kernel}/dtbs dtbs
        )
        (
        cd mobile-nixos/recovery
        cp -v ${recovery.mobile.outputs.initrd} stage-1
        cp -v ${kernel_file} kernel
        cp -vr ${kernel}/dtbs dtbs
        )
        cp -v ${bootscr} ./boot.scr
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

  # Without bootloader means "without u-boot"
  withoutBootloader = imageBuilder.diskImage.makeGPT {
    name = "mobile-nixos";
    diskID = "01234567";
    headerHole = cfg.initialGapSize;

    # This has to follow the same order as defined in the u-boot bootloaders...
    # This is not ideal... an alternative solution should be figured out.
    partitions = [
      miscPartition
      persistPartition
      boot-partition
      config.mobile.outputs.generatedFilesystems.rootfs
    ];
  };

  burnCommands = family: (
    let
      commands = {
        allwinner = ''
          dd if=${cfg.package}/u-boot-sunxi-with-spl.bin of=$out bs=1024 seek=8 conv=notrunc
        '';
        rockchip = ''
          dd if=${cfg.package}/idbloader.img of=$out bs=512 seek=64 conv=notrunc
          dd if=${cfg.package}/u-boot.itb    of=$out bs=512 seek=16384 conv=notrunc
        '';
      };
    in
    if commands ? "${family}"
    then commands.${family}
    else throw "No u-boot burn commands for SoC family '${family}'"
  );

  withBootloader = runCommandNoCC "${deviceName}_full-disk-image.img" {} ''
    cp -v ${withoutBootloader}/mobile-nixos.img $out
    chmod +w $out
    echo ":: Burning bootloader"
    (
    PS4=" $ "
    set -x
    ${burnCommands soc.family}
    )
    echo ":: Burned"
  '';
in
{
  options.mobile = {
    quirks.u-boot = {
      soc.family = mkOption {
        type = types.enum [ "allwinner" "rockchip" ];
        internal = true;
        description = ''
          The (internal to this project) family name for the bootloader.
          This is used to build upon assumptions like the location on the
          backing storage that u-boot will be "burned" at.
        '';
      };
      package = mkOption {
        type = types.package;
        description = ''
          Which package handles u-boot for this system.
        '';
      };
      initialGapSize = mkOption {
        type = types.int;
        description = ''
          Size (in bytes) to keep reserved in front of the first partition.
        '';
      };
      additionalCommands = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Additional U-Boot commands to run.
        '';
      };
    };

    outputs = {
      u-boot = {
        boot-partition = mkOption {
          type = types.package;
          description = ''
            Boot partition for the system.
          '';
          visible = false;
        };
        disk-image = lib.mkOption {
          type = types.package;
          description = ''
            Full Mobile NixOS disk image for a u-boot-based system.
          '';
          visible = false;
        };
        u-boot = mkOption {
          type = types.package;
          description = ''
            U-Boot build for the system.
          '';
          visible = false;
        };
      };
    };
  };

  config = lib.mkMerge [
    { mobile.system.types = [ "u-boot" ]; }
    (mkIf enabled {
      nixpkgs.overlays = [(final: super: {
        device = {
          u-boot = cfg.package;
        };
      })];
      mobile.outputs = {
        default = config.mobile.outputs.u-boot.disk-image;
        u-boot = {
          inherit boot-partition;
          disk-image = withBootloader;
          u-boot = cfg.package;
        };
      };
    })
  ];
}
