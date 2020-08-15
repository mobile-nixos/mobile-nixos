{
  mobile-nixos
, fetchFromGitHub
, fetchpatch
, kernelPatches ? [] # FIXME
}:

(mobile-nixos.kernel-builder {
  version = "5.8.0";
  configfile = ./config.aarch64;
  src = fetchFromGitHub {
    owner = "mobile-nixos";
    repo = "linux";
    rev = "555692adddc0e74946e6f0a32fee1b0cd21bbbc3";
    sha256 = "0njq3r1g39rh1xgrk9bgscqx9cj6nvs7y8jjcdqjkb6pbrc3kfmy";
  };
  patches = [
    ./0001-dts-pinephone-Setup-default-on-and-panic-LEDs.patch
  ];
}).overrideAttrs({ postInstall ? "", ... }: {
  installTargets = [ "install" "dtbs" ];
  postInstall = postInstall + ''
    mkdir -p "$out/dtbs/allwinner"
    cp -v $buildRoot/arch/arm64/boot/dts/allwinner/sun50i-a64-pinephone-*.dtb $out/dtbs/allwinner/
  '';
})
