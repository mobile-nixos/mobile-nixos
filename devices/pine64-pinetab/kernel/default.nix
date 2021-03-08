{
  mobile-nixos
, fetchFromGitHub
, ...
}:

mobile-nixos.kernel-builder {
  version = "5.11.2";
  configfile = ./config.aarch64;
  src = fetchFromGitHub {
    # https://github.com/megous/linux
    owner = "megous";
    repo = "linux";
    # orange-pi-5.11
    rev = "945310589fa62cb25f54e885c4c3f43b31fa009b";
    sha256 = "1ygha48bvm14dahlni0wrc3r3c8pc5dj3bdhmvqx2lrb52mfiasc";
  };

  patches = [
    ./0001-pinetab-enable-jack-detection.patch
    ./0002-pinetab-enable-hdmi.patch
    ./0003-pinetab-enable-rtl8723cs-bluetooth.patch
    ./0004-pinetab-enable-bma223-accelerometer.patch
  ];

  # Install *only* the desired FDTs
  postInstall = ''
    echo ":: Installing FDTs"
    mkdir -p "$out/dtbs/allwinner"
    cp -v $buildRoot/arch/arm64/boot/dts/allwinner/sun50i-a64-pinetab.dtb $out/dtbs/allwinner/
  '';

  isCompressed = false;
}
