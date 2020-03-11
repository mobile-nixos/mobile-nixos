{
  mobile-nixos
, fetchFromGitLab
, fetchpatch
, kernelPatches ? [] # FIXME
}:

(mobile-nixos.kernel-builder {
  version = "5.5.0";
  configfile = ./config.aarch64;
  src = fetchFromGitLab {
    owner = "pine64-org";
    repo = "linux";
    rev = "94cf851f0f4443c771a926102dee497def319b49";
    sha256 = "1a4ch2j8hla3xd7rv38ra6bnv14lsnj0srhlh1c8vxxvwywzg815";
  };
  patches = [
  ];
}).overrideAttrs({ postInstall ? "", ... }: {
  installTargets = [ "install" "dtbs" ];
  postInstall = postInstall + ''
    mkdir -p "$out/dtbs/allwinner"
    cp -v "$buildRoot/arch/arm64/boot/dts/allwinner/sun50i-a64-pinephone.dtb" "$out/dtbs/allwinner/"
  '';
})
