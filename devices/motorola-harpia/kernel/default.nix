{ mobile-nixos
, fetchFromGitHub
, ...
}:

let
  src = fetchFromGitHub {
    owner = "msm8916-mainline";
    repo = "linux";
    rev = "6cc2342c6a7227a05ca94c836df42d5ba273eef2";  #  branch msm8916/6.7-rc4
    sha256 = "sha256-zyAfQwiGx6vCdfRpnZl4qTqAM5TkIda7E0APnDiSF3E=";
  };
in
mobile-nixos.kernel-builder {
  version = "6.7.0-rc4";
  configfile = ./config.aarch64;

  inherit src;
  # bq24296 is charger-related
  # max170xx_battery

  patches = [
    ./pstore-and-simplefb-harpia.patch
  ];
  isModular = true;
}
