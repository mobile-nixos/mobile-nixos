{ mobile-nixos
, fetchFromGitHub
, fetchpatch
, ...
}:

mobile-nixos.kernel-builder {
  version = "6.15.0";
  configfile = ./config.aarch64;
#   configfile = ./config.aarch64;

  src = fetchFromGitHub {
    owner = "msm8953-mainline";
    repo = "linux";
    rev = "v6.15.0-r0";
#     hash = "sha256-TaR14+u58vXCPse9MoTJg+GDV5yXPGRhc/eeVUbNZE8=";
    hash = "sha256-0KUOEQyrwKUzS+lVxPIaz2rELLcC6VPIG8B9+WkngLc=";
  };

  patches = [
    # NixOS-specific patch for Kernel build
#     ./modinst-arg-list-too-long.patch
  ];

#   patches = [
#     # ASoC: codecs: tas2559: Fix build
#     (fetchpatch {
#       url = "https://github.com/samueldr/linux/commit/d1b59edd94153ac153043fb038ccc4e6c1384009.patch";
#       sha256 = "sha256-zu1m+WNHPoXv3VnbW16R9SwKQzMYnwYEUdp35kUSKoE=";
#     })
#   ];

  isModular = true;
}
