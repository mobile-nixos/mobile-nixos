{ lib
, writeText
, callPackage
, buildUBoot
, armTrustedFirmwareAllwinner
, fetchpatch
, fetchurl
}:

let
  pw = id: sha256: fetchpatch {
    inherit sha256;
    name = "${id}.patch";
    url = "https://patchwork.ozlabs.org/patch/${id}/raw/";
  };
in
(buildUBoot {
  defconfig = "pinephone_defconfig";
  extraMeta.platforms = ["aarch64-linux"];
  BL31 = "${armTrustedFirmwareAllwinner}/bl31.bin";

  extraPatches = [
    # https://patchwork.ozlabs.org/patch/1202024
    (pw "1202024" "0c196zk1s3pq3wdv909sxmjgqpll2hwb817bpbghkfkyyknl96vg")

    # Adapted from: https://gitlab.com/pine64-org/u-boot/-/tree/crust
    # This drops the commits irrelevant for the pinephone.
    ./minimal-crust-support.patch
  ];

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
  '';
}).overrideAttrs(old: rec {
  version = "2020.07";
  src = fetchurl {
    url = "ftp://ftp.denx.de/pub/u-boot/u-boot-${version}.tar.bz2";
    sha256 = "0sjzy262x93aaqd6z24ziaq19xjjjk5f577ivf768vmvwsgbzxf1";
  };
  postInstall = ''
    cp .config $out/build.config
  '';
  postPatch = old.postPatch + ''
    cat $extraConfigPath >> configs/$defconfig
  '';
})
