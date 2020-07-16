{
  mobile-nixos
, fetchFromGitLab
, fetchpatch
, kernelPatches ? [] # FIXME
, hardware ? {}
}:

(mobile-nixos.kernel-builder {
  version = "5.6.0";
  configfile = ./config.aarch64;
  src = fetchFromGitLab {
    owner = "pine64-org";
    repo = "linux";
    rev = "14c4d9ddc15f60645bd262b315fc7d770a44a1c6";
    sha256 = "137l1y6g3lfmqhxxixdph42cy72398nlmbwmk4690w2anlj76f3s";
  };
  patches = [
    ./0001-dts-pinephone-Setup-default-on-and-panic-LEDs.patch
  ];
}).overrideAttrs({ postInstall ? "", ... }: {
  installTargets = [ "install" "dtbs" ];
  postInstall = postInstall + ''
    mkdir -p "$out/dtbs/allwinner"
    cp -v "$buildRoot/arch/arm64/boot/dts/allwinner/sun50i-a64-pinephone-${hardware.rev}.dtb" "$out/dtbs/allwinner/sun50i-a64-pinephone.dtb"
  '';
})
