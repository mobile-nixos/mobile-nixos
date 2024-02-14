{ mobile-nixos
, fetchFromGitHub
, ...
}:

mobile-nixos.kernel-builder {
  version = "6.7.0-rc4";
  configfile = ./config.aarch64;

  src = fetchFromGitHub {
    owner = "msm8916-mainline";
    repo = "linux";
    rev = "6cc2342c6a7227a05ca94c836df42d5ba273eef2";  #  branch msm8916/6.7-rc4
    sha256 = "sha256-zyAfQwiGx6vCdfRpnZl4qTqAM5TkIda7E0APnDiSF3E=";
  };

  isModular = true;
}
