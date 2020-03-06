{
  mobile-nixos
, fetchFromGitLab
, fetchpatch
, kernelPatches ? [] # FIXME
}:

(mobile-nixos.kernel-builder {
  version = "5.5.0-rc7";
  configfile = ./config.aarch64;
  src = fetchFromGitLab {
    domain = "gitlab.manjaro.org";
    owner = "tsys";
    repo = "linux-pinebook-pro";
    rev = "b3ba5b2b87e9bd191265776b93277e49d044b79e";
    sha256 = "1fj6gkpy422lw23qg0hwyv5hbfx3pfhgv67ma44ly2mxmgna4nsh";
  };
  patches = [
  ];
}).overrideAttrs({ postInstall ? "", postPatch ? "", ... }: {
  installTargets = [ "install" "dtbs" ];
  postInstall = postInstall + ''
    mkdir -p $out/dtbs/rockchip
    cp -v "$buildRoot/arch/arm64/boot/dts/rockchip/rk3399-pinebook-pro.dtb" "$out/dtbs/rockchip/"
  '';
})

