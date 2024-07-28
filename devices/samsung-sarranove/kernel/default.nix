{ mobile-nixos
, fetchFromGitHub
, ...
}:

mobile-nixos.kernel-builder {
  version = "6.7-rc4";
  configfile = ./config.arm;

  src = fetchFromGitHub {
    owner = "msm8916-mainline";
    repo = "linux";
    rev = "6cc2342c6a7227a05ca94c836df42d5ba273eef2"; # branch msm8916/6.7-rc4
    # TODO(Krey): Needs to be adjusted
    sha256 = "sha256-mWd6FsGCPzC2DTQ23WxgItsq5gHdoPMXEMOhH5C3p2g=";
  };

  isModular = true;
}
