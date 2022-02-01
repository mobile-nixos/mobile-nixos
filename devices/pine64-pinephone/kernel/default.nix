{
  mobile-nixos
, fetchFromGitHub
, fetchpatch
, ...
}:

mobile-nixos.kernel-builder {
  version = "5.16.4";
  configfile = ./config.aarch64;
  src = fetchFromGitHub {
    # https://github.com/megous/linux
    owner = "megous";
    repo = "linux";
    # orange-pi-5.16
    rev = "c45edf5ecf5d08b44a885b05433d9c15d18d5ab1";
    hash = "sha256-bRbi/6+wITxoYRgHSzN5ypZfoZ3PiWW1ETQ8toHlMl8=";
  };
  patches = [
    ./0001-dts-pinephone-Setup-default-on-and-panic-LEDs.patch
    (fetchpatch {
      url = "https://github.com/mobile-nixos/linux/commit/372597b5449b7e21ad59dba0842091f4f1ed34b2.patch";
      sha256 = "1lca3fdmx2wglplp47z2d1030bgcidaf1fhbnfvkfwk3fj3grixc";
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
