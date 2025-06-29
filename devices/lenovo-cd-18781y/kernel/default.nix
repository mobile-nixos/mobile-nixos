{ mobile-nixos
, fetchFromGitHub
, fetchpatch
, ...
}:

mobile-nixos.kernel-builder {
  version = "6.12.0";
#   configfile = ./config-postmarketos-qcom-msm8953.aarch64;
  configfile = ./config.aarch64;

  src = fetchFromGitHub {
    owner = "msm8953-mainline";
    repo = "linux";
    rev = "v6.12.0-r2";
    hash = "sha256-TaR14+u58vXCPse9MoTJg+GDV5yXPGRhc/eeVUbNZE8=";
  };

#   patches = [
#     # ASoC: codecs: tas2559: Fix build
#     (fetchpatch {
#       url = "https://github.com/samueldr/linux/commit/d1b59edd94153ac153043fb038ccc4e6c1384009.patch";
#       sha256 = "sha256-zu1m+WNHPoXv3VnbW16R9SwKQzMYnwYEUdp35kUSKoE=";
#     })
#   ];

  isModular = true;
}
