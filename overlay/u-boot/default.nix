{ lib, callPackage, buildUBoot, armTrustedFirmwareAllwinner, fetchgit, ... }:

let
  # CONFIG_BOOTCOMMAND is built using these.
  # This shows up a fun menu.
  cmds = lib.concatStringsSep ";" [
    "setenv bootmenu_0 Generic distro=run distro_bootcmd"
    "setenv bootmenu_1 Fastboot=fastboot usb 0"
    "setenv bootmenu_2 Reset board=reset"
    "bootmenu 5"
  ];
in
{
  sopine-qcdt = (buildUBoot {
    defconfig = "sopine_baseboard_defconfig";
    extraMeta.platforms = ["aarch64-linux"];
    BL31 = "${armTrustedFirmwareAllwinner}/bl31.bin";

    extraPatches = [
      ./0001-fastboot-boot-gives-enough-space-to-fit-a-pointer.patch
      ./0002-image-android-Adds-support-for-FDT-in-the-qcom-forma.patch
      ./0003-Loads-FDT-from-qualcomm-specific-format-of-android-b.patch
	  ./xxxx-sopine_defconfig.patch
    ];

    filesToInstall = ["u-boot-sunxi-with-spl.bin" "u-boot.img" "u-boot.dtb"];

    # FIXME: figure out why extraConfig builds with equivalent config to `xxxx` patch doesn't work.
    #extraConfig = ''
    #  CONFIG_BOOTCOMMAND="${cmds}"

    #  CONFIG_USB_MUSB_GADGET=y
    #  CONFIG_USB_FUNCTION_FASTBOOT=y
	#  CONFIG_FASTBOOT_FLASH=y
	#  CONFIG_USBDOWNLOAD_GADGET=y

    #  # SD card as flashing target for fastboot
    #  CONFIG_FASTBOOT_FLASH_MMC_DEV=0

    #  CONFIG_CMD_BOOTMENU=y
    #  CONFIG_CFB_CONSOLE_ANSI=y
    #  '';
  }).overrideAttrs(old: rec {
    version = "2019.01";
    src = fetchgit {
	  #url = http://git.denx.de/u-boot.git;
	  url = git://git.denx.de/u-boot.git;
      sha256 = "10c6vlppkpfx9c4b4mn6faaf71zb0rszch80s45h5w6kjmr6j6ig";
	  rev = "2f41ade79e5969ebea03a7dcadbeae8e03787d7e";
    };
  });
}
