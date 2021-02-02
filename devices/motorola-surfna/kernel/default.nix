{
  mobile-nixos
, fetchFromGitHub
, ...
}:

mobile-nixos.kernel-builder-gcc49 {
  version = "4.9.112";
  configfile = ./config.aarch64;

  src = fetchFromGitHub {
    owner = "mobile-nixos";
    repo = "linux";
    rev = "f94feb0d419573e219bb15e9f4a7c839e1f1543a"; # mobile-nixos/motorola-surfna
    sha256 = "09bn08g0qcsp0b134lsd0kvcx7mlcs2cckix7bqq23m6bzrnxy54";
  };

  patches = [
    ./0001-mobile-nixos-Workaround-selected-processor-does-not-.patch
    ./0001-mobile-nixos-Adds-and-sets-BGRA-as-default.patch
    ./0003-arch-arm64-Add-config-option-to-fix-bootloader-cmdli.patch
  ];

  enableRemovingWerror = true;
  isImageGzDtb = true;
  isModular = false;
}
