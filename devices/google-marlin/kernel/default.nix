{
  mobile-nixos
, fetchFromGitHub
, ...
}:

mobile-nixos.kernel-builder-gcc6 {
  configfile = ./config.aarch64;

  version = "3.18.140";
  src = fetchFromGitHub {
    owner = "android-linux-stable";
    repo = "marlin";
    rev = "b69581b25fa7273424ef78aa82c3fd1dc05db0a9";
    sha256 = "02jj6zxkxx6cynq0rdq4249ns8wwwkybpdkp6gsi7v0y8czfdaj7";
  };

  patches = [
    ./0001-Revert-four-tty-related-commits.patch
    ./0003-arch-arm64-Add-config-option-to-fix-bootloader-cmdli.patch
    ./99_framebuffer.patch
  ];

  enableRemovingWerror = true;
  isImageGzDtb = true;
  isModular = false;
}
