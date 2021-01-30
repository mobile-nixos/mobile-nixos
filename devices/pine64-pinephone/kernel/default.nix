{
  mobile-nixos
, fetchFromGitHub
, ...
}:

mobile-nixos.kernel-builder {
  version = "5.10.0";
  configfile = ./config.aarch64;
  src = fetchFromGitHub {
    # https://github.com/megous/linux
    owner = "megous";
    repo = "linux";
    # orange-pi-5.10
    rev = "cf48c321c3ebd42d33234bf5fc1b7f8b4de86c95";
    sha256 = "0p6gnxc80m7l3mw89fljpysayf269b09xk88z4nyfv92z0gn6yiv";
  };
  patches = [
    ./0001-dts-pinephone-Setup-default-on-and-panic-LEDs.patch
  ];

  # Install *only* the desired FDTs
  postInstall = ''
    echo ":: Installing FDTs"
    mkdir -p "$out/dtbs/allwinner"
    cp -v $buildRoot/arch/arm64/boot/dts/allwinner/sun50i-a64-pinephone-*.dtb $out/dtbs/allwinner/
  '';

  isCompressed = false;
}
