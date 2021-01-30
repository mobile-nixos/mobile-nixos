{
  mobile-nixos
, fetchFromGitHub
, ...
}:

mobile-nixos.kernel-builder {
  configfile = ./config.aarch64;

  version = "4.4.230";
  src = fetchFromGitHub {
    owner = "android-linux-stable";
    repo = "wahoo";
    rev = "b7a52ef11ab0e2f59ac8d6034821bee07145b44c";
    sha256 = "0npmpsv6mid9vd7yqbnzx83ddhqxdmjfh0mpl06gqx4ywqbc8ph0";
  };

  patches = [
    ./0001-Revert-four-tty-related-commits.patch
    ./0001-mobile-nixos-Adds-and-sets-BGRA-as-default.patch
    ./0001-mobile-nixos-Workaround-selected-processor-does-not-.patch
    ./0003-arch-arm64-Add-config-option-to-fix-bootloader-cmdli.patch
  ];

  enableRemovingWerror = true;
  isImageGzDtb = true;
  isModular = false;
}
