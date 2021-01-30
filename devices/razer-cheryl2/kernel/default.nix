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
    rev = "fd5380e2c5e216f677d2c1d999154d014e5b9e00";
    sha256 = "1idqpynhifll9hq4m5kv38z19kkk4222zw6sa3a5lxvrai4484lb";
  };

  patches = [
    ./0001-mobile-nixos-Workaround-selected-processor-does-not-.patch
    ./0003-arch-arm64-Add-config-option-to-fix-bootloader-cmdli.patch
  ];

  enableRemovingWerror = true;
  isImageGzDtb = true;
  isModular = false;
}
