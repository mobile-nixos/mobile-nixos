{
  mobile-nixos
, fetchFromGitHub
}:

mobile-nixos.kernel-builder {
  version = "5.9.0";
  configfile = ./config.aarch64;
  src = fetchFromGitHub {
    # https://github.com/megous/linux
    owner = "megous";
    repo = "linux";
    # orange-pi-5.9
    rev = "e98db7f114d7602c6b847d76e183787f0c97cf5b";
    sha256 = "007j5r0ygy7sfs7d49qx623irl8a9rl7ppl9159jj419izplrzyf";
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
