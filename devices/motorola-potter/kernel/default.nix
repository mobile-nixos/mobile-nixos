{ mobile-nixos
, fetchFromGitHub
, ...
}:

mobile-nixos.kernel-builder {
  version = "6.5.2";
  configfile = ./config.aarch64;

  src = fetchFromGitHub {
    owner = "msm8953-mainline";
    repo = "linux";
    rev = "e7797492485f14684f5575f82800d09508df2034"; # 6.5.2/ipa
    hash = "sha256-iJl4+2W96IlBiWiSq58ZAWgO3L3wNmuNLbmkCjCID1Y=";
  };

  isModular = true;
}
