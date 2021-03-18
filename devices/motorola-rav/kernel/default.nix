{
  mobile-nixos
, fetchFromGitHub
, ...
}:

mobile-nixos.kernel-builder-clang_8 {
  version = "4.14.117";
  configfile = ./config.aarch64;

  src = fetchFromGitHub {
    owner = "MotorolaMobilityLLC";
    repo = "kernel-msm";
    rev = "efdfc01dfa6001d47f3e2d186df5e5222914dd03"; # MMI-QPJS30.131-43-2
    sha256 = "1wcp79bxkx8wlbhvrjv7kdv62k16cps6mr1f18n0hcmajfwk8pvg";
  };

  patches = [
    ./0003-arch-arm64-Add-config-option-to-fix-bootloader-cmdli.patch
  ];

  enableRemovingWerror = true;
  isImageGzDtb = true;
  isModular = false;
}
