{
  mobile-nixos
, fetchFromGitLab
, fetchpatch
, kernelPatches ? [] # FIXME
}:

(mobile-nixos.kernel-builder {
  version = "5.6.0";
  configfile = ./config.aarch64;
  src = fetchFromGitLab {
    owner = "pine64-org";
    repo = "linux";
    rev = "2a6074e53b019db8a4a63cb255bc29422db3fe19";
    sha256 = "1rjs2wvbbq69mzr6i3hjdbwsr61gflzvgx13z5hf89gcp29idmcp";
  };
  patches = [
    ./0001-dts-pinephone-Setup-default-on-and-panic-LEDs.patch
    ./disable-power-save.patch
  ];
}).overrideAttrs({ postInstall ? "", ... }: {
  installTargets = [ "install" "dtbs" ];
  postInstall = postInstall + ''
    mkdir -p "$out/dtbs/allwinner"
    cp -v "$buildRoot/arch/arm64/boot/dts/allwinner/sun50i-a64-pinephone-1.1.dtb" "$out/dtbs/allwinner/sun50i-a64-pinephone.dtb"
  '';
})
