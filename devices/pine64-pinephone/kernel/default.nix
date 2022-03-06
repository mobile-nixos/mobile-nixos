{
  mobile-nixos
, fetchFromGitHub
, fetchpatch
, ...
}:

mobile-nixos.kernel-builder {
  version = "5.13.7";
  configfile = ./config.aarch64;
  src = fetchFromGitHub {
    # https://github.com/megous/linux
    owner = "megous";
    repo = "linux";
    # orange-pi-5.13
    rev = "b1f383fd3c70e21a8062fdc3f59403d2a26edc9f";
    sha256 = "0m1jhkq6lxp12a302r80qbz8l1sdmqnwfymg1lx68c91dm7j3wkf";
  };
  patches = [
    ./0001-dts-pinephone-Setup-default-on-and-panic-LEDs.patch
    (fetchpatch {
      url = "https://github.com/mobile-nixos/linux/commit/372597b5449b7e21ad59dba0842091f4f1ed34b2.patch";
      sha256 = "1lca3fdmx2wglplp47z2d1030bgcidaf1fhbnfvkfwk3fj3grixc";
    })
    # Drop modem-power from DT to allow eg25-manager to have full control.
    (fetchpatch {
      url = "https://gitlab.com/postmarketOS/pmaports/-/raw/164e9f010dcf56642d8e6f422a994b927ae23f38/device/main/linux-postmarketos-allwinner/0007-dts-pinephone-drop-modem-power-node.patch";
      sha256 = "nYCoaYj8CuxbgXfy5q43Xb/ebe5DlJ1Px571y1/+lfQ=";
    })
  ];

  # Install *only* the desired FDTs
  postInstall = ''
    echo ":: Installing FDTs"
    mkdir -p "$out/dtbs/allwinner"
    cp -v $buildRoot/arch/arm64/boot/dts/allwinner/sun50i-a64-pinephone-*.dtb $out/dtbs/allwinner/
  '';

  isCompressed = false;
}
