{ lib, writeText, callPackage, buildUBoot, armTrustedFirmwareAllwinner, fetchFromGitLab }:

# TODO: mobile-nixos.buildUBoot
let
  # FIXME : at runtime, detect the storage. This currently hardcodes one of the mmc devices...
  # mmc_bootdev=0 # is set to the booted mmc identifier on sunxi...
  # TODO : implement the same elsewhere :/
  mmc = "0";
  mmcLetter = if mmc == "0" then "a" else "b"; # ... limits to two

  # Marks a partition with a name for fastboot.
  mkPart = name: num: "setenv fastboot_partition_alias_${name} mmcsd${mmcLetter}${toString num}";

  # FIXME: as a configuration option.
  base = "0x42000000";

  cmds = lib.concatStringsSep ";" [
    (mkPart "boot"     1)
    (mkPart "recovery" 2)
    (mkPart "system"   3)
    #(mkPart "userdata" 4) # No, we're not using `userdata` in these systems.
    "setenv bootmenu_0 System='  part start mmc ${mmc} 1 start; part size mmc ${mmc} 1 size; mmc read ${base} $start $size;bootm ${base}'"
    "setenv bootmenu_1 Recovery='part start mmc ${mmc} 2 start; part size mmc ${mmc} 2 size; mmc read ${base} $start $size;bootm ${base}'"
    "setenv bootmenu_2 Generic distro=run distro_bootcmd"
    "setenv bootmenu_3 Fastboot=fastboot usb 0"
    "setenv bootmenu_4 Reset board=reset"
    "bootmenu 2"
  ];
in
  (buildUBoot {
    defconfig = "sopine_baseboard_defconfig";
    extraMeta.platforms = ["aarch64-linux"];
    BL31 = "${armTrustedFirmwareAllwinner}/bl31.bin";

    extraPatches = [
      ./0001-image-android-Adds-support-for-FDT-in-the-qcom-forma.patch
      ./0002-Loads-FDT-from-qualcomm-specific-format-of-android-b.patch
    ];

    filesToInstall = ["u-boot-sunxi-with-spl.bin" "u-boot.img" "u-boot.dtb"];

    extraConfig = ''
      CONFIG_BOOTCOMMAND="${cmds}"

      CONFIG_USB_MUSB_GADGET=y
      CONFIG_USB_FUNCTION_FASTBOOT=y
      CONFIG_FASTBOOT_FLASH=y
      CONFIG_USB_GADGET_DOWNLOAD=y

      # There is seemingly a bug with the Kconfig options of u-boot, where this
      # option defaults to `y` when set using `make ...defconfig`, but will be
      # kept "is not set" if the option is changed either via menuconfig or by
      # setting it via our extraConfig.
      CONFIG_USB_MUSB_PIO_ONLY=y

      # SD card as flashing target for fastboot.
      CONFIG_FASTBOOT_FLASH_MMC_DEV=0

      # We rely on this for our boot images.
      CONFIG_ANDROID_BOOT_IMAGE=y

      # Allows showing a custom menu
      CONFIG_CMD_BOOTMENU=y
      CONFIG_CFB_CONSOLE_ANSI=y

      # The default autoboot doesn't *wait*.
      # Though any input before will cancel it.
      # This is because we re-invest the 2s in our own menu.
      CONFIG_AUTOBOOT_KEYED_CTRLC=y
      CONFIG_BOOTDELAY=0
    '';
  }).overrideAttrs(old: rec {
    version = "2019.10";
    src = fetchFromGitLab {
      domain = "gitlab.denx.de";
      owner = "u-boot";
      repo = "u-boot";
      sha256 = "0fj1dgg6nlxkxhjl1ir0ksq6mbkjj962biv50p6zh71mhbi304in";
      rev = "v${version}";
    };
    postInstall = ''
      cp .config $out/build.config
    '';
  })
