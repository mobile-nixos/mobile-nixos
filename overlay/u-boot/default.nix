{ lib, writeText, callPackage, buildUBoot, armTrustedFirmwareAllwinner, fetchgit, ... }:

let
  # CONFIG_BOOTCOMMAND is built using these.
  # This shows up a fun menu.
  base = "0x42000000";
  mmc = "0";
  mmcLetter = if mmc == "0" then "a" else "b"; # ... limits to two
  mkPart = name: num: "setenv fastboot_partition_alias_${name} mmcsd${mmcLetter}${toString num}";
  cmds = lib.concatStringsSep ";" [
    (mkPart "boot"     1)
    (mkPart "recovery" 2)
    (mkPart "system"   3)
    (mkPart "userdata" 4)
    "setenv bootmenu_0 System='  part start mmc ${mmc} 1 start; part size mmc ${mmc} 1 size; mmc read ${base} $start $size;bootm ${base}'"
    "setenv bootmenu_1 Recovery='part start mmc ${mmc} 2 start; part size mmc ${mmc} 2 size; mmc read ${base} $start $size;bootm ${base}'"
    "setenv bootmenu_2 Generic distro=run distro_bootcmd"
    "setenv bootmenu_3 Fastboot=fastboot usb 0"
    "setenv bootmenu_4 Reset board=reset"
    "bootmenu 5"
  ];
in
{
  sopine-qcdt = (buildUBoot {
    defconfig = "sopine_baseboard_defconfig";
    extraMeta.platforms = ["aarch64-linux"];
    BL31 = "${armTrustedFirmwareAllwinner}/bl31.bin";

    extraPatches = [
      ./0001-image-android-Adds-support-for-FDT-in-the-qcom-forma.patch
      ./0002-Loads-FDT-from-qualcomm-specific-format-of-android-b.patch

      # FIXME : figure out a more generic way to handle this
      (writeText "xxxx-sopine_defconfig.patch" ''
diff --git a/configs/sopine_baseboard_defconfig b/configs/sopine_baseboard_defconfig
index 0a189fc03d..4b9582adbb 100644
--- a/configs/sopine_baseboard_defconfig
+++ b/configs/sopine_baseboard_defconfig
@@ -19,3 +19,15 @@ CONFIG_SUN8I_EMAC=y
 CONFIG_USB_OHCI_HCD=y
 CONFIG_USB_EHCI_HCD=y
 CONFIG_SYS_USB_EVENT_POLL_VIA_INT_QUEUE=y
+
+CONFIG_BOOTCOMMAND="${cmds}"
+
+CONFIG_USB_MUSB_GADGET=y
+CONFIG_USB_FUNCTION_FASTBOOT=y
+CONFIG_FASTBOOT_FLASH=y
+
+# SD card as flashing target for fastboot
+CONFIG_FASTBOOT_FLASH_MMC_DEV=${mmc}
+
+CONFIG_CMD_BOOTMENU=y
+CONFIG_CFB_CONSOLE_ANSI=y
      '')
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
    version = "2019.04";
    src = fetchgit {
	  url = git://git.denx.de/u-boot.git;
      sha256 = "1vc6dh9a0bjwgs8x5cl282gasn0hqcvjfsipgf7hyxq5jrhl3qyg";
	  rev = "v${version}";
    };
  });
}
