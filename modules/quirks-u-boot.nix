{ config, lib, pkgs, ... }:

#
# This defines a "quasi-system type", for u-boot using targets. This is used to
# build a system compatible with the "android" system type, but actually using
# u-boot as a bootloader.
#
# When using such a "quasi-system type",
#
let
  inherit (pkgs) hostPlatform imageBuilder runCommandNoCC;
  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.mobile.quirks.u-boot;
  inherit (cfg) soc;
  inherit (config) system;
  deviceName = config.mobile.device.name;

  mkBootImgPart = { name, image, size }:
      (runCommandNoCC "${deviceName}_${name}.img-partition" {
        inherit name image;
        filename = "${name}.img";
        filesystemType = "boot.img";
      } ''
        mkdir -p $out
        (
        PS4=" $ "
        set -x
        truncate --size ${toString size} $out/$filename
        dd if=${image} of=$out/$filename conv=notrunc
        )
      '')
;

  withoutBootloader = imageBuilder.diskImage.makeMBR {
    name = "mobile-nixos";
    diskID = "01234567";

    # This has to follow the same order as defined in the u-boot bootloaders...
    # This is not ideal... an alternative solution should be figured out.
    partitions = [
      (imageBuilder.gap (imageBuilder.size.MiB 10))

      (mkBootImgPart {
        name = "boot";
        size = imageBuilder.size.MiB 32;
        image = system.build.android-bootimg;
      })
      (mkBootImgPart {
        name = "recovery";
        size = imageBuilder.size.MiB 32;
        # FIXME: figure out a "recovery" strategy...
        image = system.build.android-bootimg;
      })

      (
      if hostPlatform.system == builtins.currentSystem
      then config.system.build.rootfs
      else (builtins.trace "WARNING: Using dummy empty filesystem as we're cross-compiling."
        (imageBuilder.fileSystem.makeExt4 {
          bootable = true;
          name = "NIXOS";
          partitionID = "44444444-4444-4444-8888-888888888888";
          size = imageBuilder.size.GiB 3;
          populateCommands = ''
            # no-op
          '';
        }))
      )
    ];
  };

  burnCommands = family: (
    let
      commands = {
        allwinner = ''
          dd if=${cfg.package}/u-boot-sunxi-with-spl.bin of=$out bs=1024 seek=8 conv=notrunc
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
      system.enable = mkEnableOption "adding a u-boot based full system build";
      soc.family = mkOption {
        type = types.enum [ "allwinner" ];
        internal = true;
        description = ''
          The (internal to this project) family name for the bootloader.
          This is used to build upon assumptions like the location on the
          backing storage that u-boot will be "burned" at.
        '';
      };
      package = mkOption {
        type = types.package;
        #default = null;
        description = ''
          Which package handles u-boot for this system.
        '';
      };
    };
  };

  config = mkIf cfg.system.enable {
    nixpkgs.overlays = [(final: super: {
      device = {
        u-boot = cfg.package;
      };
    })];
    system.build = {
      # TODO: prefer using makeGPT, and a holey-like system...
      diskImage = withBootloader;
    };
  };
}
