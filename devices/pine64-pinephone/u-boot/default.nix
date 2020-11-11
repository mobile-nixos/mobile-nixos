{ lib
, writeText
, callPackage
, buildUBoot
, armTrustedFirmwareAllwinner
, fetchpatch
, fetchFromGitLab
}:

(buildUBoot {
  defconfig = "pinephone_defconfig";
  extraMeta.platforms = ["aarch64-linux"];
  BL31 = "${armTrustedFirmwareAllwinner}/bl31.bin";

  filesToInstall = ["u-boot-sunxi-with-spl.bin" "u-boot.img" "u-boot.dtb"];

  # The current u-boot build doesn't know about the USB controllers.
  # When it will, ths will allow enabling usb mass storage gadget.
  #  CONFIG_USB_MUSB_GADGET=y
  #  CONFIG_CMD_USB_MASS_STORAGE=y
  extraConfig = ''
    # The default autoboot doesn't *wait*.
    # Though any input before will cancel it.
    # This is because we re-invest the 2s in our own menu.
    CONFIG_AUTOBOOT_KEYED_CTRLC=y
    CONFIG_BOOTDELAY=0
    CONFIG_REGEX=y
  '';
}).overrideAttrs(old: rec {
  src = fetchFromGitLab {
    repo = "u-boot";
    owner = "pine64-org";
    rev = "495f85a398272e6d8ea8142790158afa1bb29c77";
    sha256 = "1w8yr24naxcqkrrcgvcxm6sq6djggnkfwslnb1gdcn9slgiysvq6";
  };
  postInstall = ''
    cp .config $out/build.config
  '';
  postPatch = old.postPatch + ''
    cat $extraConfigPath >> configs/$defconfig
  '';
})
