{ config, pkgs, lib, modules, baseModules, ... }:

let
  enabled = config.mobile.system.type == "lk2nd";

  inherit (lib) concatStringsSep optionalString types;
  inherit (config.mobile.outputs) recovery stage-0;
  inherit (config.mobile) device;
  inherit (stage-0.mobile.boot.stage-1) kernel;

  kernelPackage = kernel.package;

  inherit (config.mobile.generatedFilesystems) rootfs;

  extlinux-bootimg = pkgs.runCommand "extlinux-${device.name}"
    {
      nativeBuildInputs = [ pkgs.e2fsprogs ];
    } ''
    mkdir image
    ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./image/
    blocks=$(du -s ./image  | cut -f1)
    rounded=$(( $blocks * 6 / 5 ))
    mkfs.ext2 -L nixos-boot  -d ./image $out $rounded
  '';

  flashable-images =  pkgs.runCommand "lk2nd-images-${device.name}" {} ''
    mkdir -p $out
    cp -v ${rootfs.imagePath} $out/system.img
    cp -v ${extlinux-bootimg} $out/boot.img
    cp -v ${config.mobile.outputs.lk2nd.package}/lk2nd.img $out/lk2nd.img
  '';

in
{
  options = {
    mobile = {
      outputs = {
        lk2nd = {
          extlinux-bootimg = lib.mkOption {
            type = types.package;
            description = ''
              extlinux-compatible `/boot` filesystem image
            '';
            visible = false;
          };
          package = lib.mkOption {
            type = types.package;
            description = ''
              `lk2nd.img` second-stage bootloader package for supporting mainline linux/extlinux on Android-based systems.
            '';
            visible = false;
          };

          flashable-images = lib.mkOption {
            type = types.package;
            description = ''
              flashable images for use with lk2nd
            '';
            visible = false;
          };

        };
      };
    };
  };

  config = lib.mkMerge [
    { mobile.system.types = [ "lk2nd" ]; }

    (lib.mkIf enabled {
      boot.loader.generic-extlinux-compatible.enable = true;
      mobile.bootloader.enable = false;  # conflicts with generic-extlinux-compatible
      boot.loader.grub.enable = false;

      mobile.outputs = {
        default = flashable-images;
        lk2nd = {
          inherit flashable-images extlinux-bootimg;
        };
        # does not configure `package` because that is per-SoC and
        # potentially per-device
      };
      mobile.HAL.boot.rebootModes = [
        "Android.recovery"
        "Android.bootloader"
      ];
      mobile.documentation.systemTypeFargment = ./. + "/device-notes.adoc.erb";
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
