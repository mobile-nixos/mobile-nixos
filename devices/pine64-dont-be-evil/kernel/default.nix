{
  mobile-nixos
, fetchFromGitLab
, fetchpatch
, kernelPatches ? [] # FIXME
}:

(mobile-nixos.kernel-builder {
  version = "5.3.0";
  configfile = ./config.aarch64;
  src = fetchFromGitLab {
    owner = "pine64-org";
    repo = "linux";
    rev = "f45877952070a0339c38839519558510f00ddb59";
    sha256 = "0mbxqmirpkm3idmbjws22bw39z1zfc1hxycwyw0sz4dw4adsggwp";
  };
  patches = [
    (fetchpatch {
      url = "https://gitlab.com/postmarketOS/pmaports/raw/master/main/linux-postmarketos-allwinner/touch-dts.patch";
      sha256 = "1vbmyvlmfxxgvsf6si28r7pvh1xclsx19n7616xz03c9c5bz2p4f";
    })
  ];
}).overrideAttrs({ postInstall ? "", postPatch ? "", ... }: {
  installTargets = [ "install" "dtbs" ];
  postInstall = postInstall + ''
    cp -v "$buildRoot/arch/arm64/boot/dts/allwinner/sun50i-a64-dontbeevil.dtb" "$out/"
  '';
})
