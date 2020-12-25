{ lib
, writeText
, callPackage
, buildUBoot
, armTrustedFirmwareAllwinner
, crustFirmware
, fetchpatch
, fetchurl
, fetchFromGitHub
}:

let
  pw = id: sha256: fetchpatch {
    inherit sha256;
    name = "${id}.patch";
    url = "https://patchwork.ozlabs.org/patch/${id}/raw/";
  };

  # use a version of ATF that has all the Crust goodies in it
  crustATF = armTrustedFirmwareAllwinner.overrideAttrs(old: rec {
    name = "arm-trusted-firmware-crust-${version}";
    version = "2.4";
    src = fetchFromGitHub {
      owner = "crust-firmware";
      repo = "arm-trusted-firmware";
      rev = "42b9ab0cbe6c1d687fe331c547d28489e12260c3";
      sha256 = "13q0946qk2brda1ci3bsri359ly8zhz76f2d1svnlh45rrrfn984";
    };
  });
in
(buildUBoot {
  defconfig = "pinephone_defconfig";
  extraMeta.platforms = ["aarch64-linux"];
  BL31 = "${crustATF}/bl31.bin";
  SCP = "${crustFirmware}/scp.bin";

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
    CONFIG_REGEX=y
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
