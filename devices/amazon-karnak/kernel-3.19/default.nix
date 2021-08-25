{ mobile-nixos
, lib
, fetchFromGitHub
, ...
}:

mobile-nixos.kernel-builder-gcc49 {
  version = "3.19.0-rc4";
  configfile = ./config.3.19.aarch64;

  src = fetchFromGitHub {
    owner = "mt8163";
    repo = "android_kernel_amazon_karnak";
    rev = "65a221f465b34d967ca0ec115569ca71dd136a96";
    sha256 = "sha256-vlsrBV+bs/USh+kSf37FL4+0MWIoyQCmtCtWh5iaeBc=";
  };

  patches = [
    ./90_dtbs-install.patch
  ];

  isImageGzDtb = true;
  isModular = false;
}
