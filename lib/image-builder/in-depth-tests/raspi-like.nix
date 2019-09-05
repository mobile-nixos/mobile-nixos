{ pkgs ? import <nixpkgs> {} }:

let
  inherit (pkgs) imageBuilder ubootTools;

  configTxt = pkgs.writeText "config.txt" ''
    kernel=u-boot-rpi3.bin

    # Boot in 64-bit mode.
    arm_control=0x200

    # Prevent the firmware from smashing the framebuffer setup done by the mainline kernel
    # when attempting to show low-voltage or overtemperature warnings.
    avoid_warnings=1
  '';

  scrTxt = pkgs.writeText "uboot.scr.txt" ''
    echo
    echo
    echo
    echo

    echo " **"
    echo " ** Image Builder sanity checks!"
    echo " ** This will appear to freeze since the kernel is not built with the VC4 kernel built-in."
    echo " ** Stay assured, the kernel should be panicking anyway since there is no initrd, no init, and no useful FS."
    echo " **"

    echo

    load $devtype $devnum:$distro_bootpart $kernel_addr_r boot/kernel
    booti $kernel_addr_r
  '';

  scr = pkgs.runCommandNoCC "uboot-script" {} ''
    mkdir -p $out
    ${ubootTools}/bin/mkimage \
      -A arm64 \
      -O linux \
      -T script \
      -C none \
      -n ${scrTxt} -d ${scrTxt} \
      $out/boot.scr
  '';

  # Here, we built a fictitious system cloning the AArch64 sd-image setup.
  # The chosen derivations are known to build fully when cross-compiled.
  pkgsAArch64 = (if pkgs.stdenv.isAarch64 then pkgs else pkgs.pkgsCross.aarch64-multiplatform);

  # The kernel for the device.
  kernel = pkgsAArch64.linux_rpi;

  # TODO: for completeness' sake an initrd with the vc4 driver should be built
  #       to show that this works as a self-contained demo.
in

with imageBuilder;

/**
 * This disk image is built to be functionally compatible with the usual `sd_image`
 * from NixOS, but *it is not* an actual `sd_image` compatible system.
 *
 * The main thing it aims to do is *minimally* create a bootable system.
 */
diskImage.makeMBR {
  name = "diskimage";
  diskID = "01234567";

  partitions = [
    (gap (size.MiB 10))
    (fileSystem.makeFAT32 {
      # Size-less
      name = "FIRMWARE";
      partitionID = "ABADF00D";
      extraPadding = size.MiB 10;
      populateCommands = ''
        (
        src=${pkgsAArch64.raspberrypifw}/share/raspberrypi/boot
        cp $src/bootcode.bin $src/fixup*.dat $src/start*.elf ./
        cp ${pkgsAArch64.ubootRaspberryPi3_64bit}/u-boot.bin ./u-boot-rpi3.bin
        cp ${configTxt} ./config.txt
        )
      '';
    })
    (fileSystem.makeExt4 {
      bootable = true;
      name = "NIXOS";
      partitionID = "44444444-4444-4444-8888-888888888888";
      populateCommands = ''
        mkdir -p ./boot
        cp ${kernel}/Image ./boot/kernel
        cp ${scr}/boot.scr ./boot/boot.scr
      '';
    })
  ];
}
