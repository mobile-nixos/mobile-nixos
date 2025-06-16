{ mobile-nixos
, fetchFromGitHub
, ...
}:

mobile-nixos.kernel-builder {
  version = "5.16.0";
  configfile = ./config.aarch64;

  src = fetchFromGitHub {
    owner = "msm8953-mainline";
    repo = "linux";
    rev = "c6e1854c059c7db13fa0299194f2a55137e29900";  #  branch msm8953-5.16
    sha256 = "sha256-mWd6FsGCPzC2DTQ23WxgItsq5gHdoPMXEMOhH5C3p2g=";
  };

  isModular = true;
}
