{ lib
, writeText
, callPackage
, buildUBoot
, armTrustedFirmwareAllwinner
, crustFirmware
, fetchpatch
, fetchurl
, fetchFromGitHub
, buildPackages
}:

let
  pw = id: sha256: fetchpatch {
    inherit sha256;
    name = "${id}.patch";
    url = "https://patchwork.ozlabs.org/patch/${id}/raw/";
  };

  pine64Patch = rev: sha256: fetchpatch {
    inherit sha256;
    name = "pine64-${rev}.patch";
    url = "https://gitlab.com/pine64-org/u-boot/-/commit/${rev}.patch";
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

    # Use the pinetab device tree,
    CONFIG_DEFAULT_DEVICE_TREE="sun50i-a64-pinetab"
    CONFIG_OF_LIST="sun50i-a64-pinetab"
  '';
}).overrideAttrs(old: rec {
  version = "2021.10";
  src = fetchurl {
    url = "ftp://ftp.denx.de/pub/u-boot/u-boot-${version}.tar.bz2";
    sha256 = "1m0bvwv8r62s4wk4w3cmvs888dhv9gnfa98dczr4drk2jbhj7ryd";
  };
  postInstall = ''
    cp .config $out/build.config
  '';
  postPatch = old.postPatch + ''
    cat $extraConfigPath >> configs/$defconfig
  '';
  nativeBuildInputs = [
    (buildPackages.python3.withPackages(p: [
      p.libfdt
      p.setuptools # for pkg_resources
    ]))
  ] ++ old.nativeBuildInputs;

  patches = [
    # Enable led on boot to notify user of boot status
    # https://gitlab.com/pine64-org/u-boot/-/commit/1a72bd9f5b0d75361b0852ed515d40a47c1e9bfe
    (pine64Patch "1a72bd9f5b0d75361b0852ed515d40a47c1e9bfe" "0z6md01qcsf6xwb6hyn4cgxjz2d0dhv05k5hrqp9kwsh9yghchqq")
  ];
})
