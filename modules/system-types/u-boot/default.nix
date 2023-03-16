{ config, pkgs, lib, modules, baseModules, ... }:

let
  enabled = config.mobile.system.type == "u-boot";

  inherit (config.mobile.outputs) recovery stage-0;
  inherit (pkgs) buildPackages imageBuilder runCommand;
  inherit (lib) mkIf mkOption types;
  cfg = config.mobile.quirks.u-boot;
  inherit (cfg) soc;
  deviceName = config.mobile.device.name;
  kernel = stage-0.mobile.boot.stage-1.kernel.package;
  kernel_file = "${kernel}/${if kernel ? file then kernel.file else pkgs.stdenv.hostPlatform.linux-kernel.target}";

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
    echo devtype = "$devtype"
    echo devnum = "$devnum"
    echo === end of the debug information ===
    echo

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

  bootscr = runCommand "${deviceName}-boot.scr" {
    nativeBuildInputs = [
      buildPackages.ubootTools
    ];
  } ''
    mkimage -C none -A ${ubootPlatforms.${pkgs.stdenv.targetPlatform.system}} -T script -d ${bootcmd} $out
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

  disk-image = imageBuilder.diskImage.makeGPT {
    name = config.mobile.configurationName;
    diskID = "01234567";

    partitions = [
      miscPartition
      persistPartition
      boot-partition
      config.mobile.outputs.generatedFilesystems.rootfs
    ];

    postProcess = ''
      (PS4=" $ "; set -x
      mkdir $out/nix-support
      cat <<EOF > $out/nix-support/hydra-build-products
      file disk-image $out/$filename
      EOF
      )
    '';
  };
in
{
  options.mobile = {
    quirks.u-boot = {
      additionalCommands = mkOption {
        type = types.lines;
        default = "";
        description = lib.mdDoc ''
          Additional U-Boot commands to run.
        '';
      };
    };

    outputs = {
      u-boot = {
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
            Full Mobile NixOS disk image for a u-boot-based system.
          '';
          visible = false;
        };
        u-boot = mkOption {
          type = types.package;
          description = lib.mdDoc ''
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
      mobile.outputs = {
        default = config.mobile.outputs.u-boot.disk-image;
        u-boot = {
          inherit boot-partition;
          disk-image = disk-image;
        };
      };
    })
  ];
}
