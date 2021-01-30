{ mobile-nixos
, fetchFromGitHub
, ...
}:
mobile-nixos.kernel-builder-gcc6 {
  version = "3.18.140";
  configfile = ./config.aarch64;
  src = fetchFromGitHub {
    owner = "android-linux-stable";
    repo = "tissot";
    rev = "b44882a26dc331f51417d0a9810c308f7bb82c4c";
    sha256 = "0xa7y3shmlnwq70qr87l4myn2873945czlq7wk2aw1d9qd1b95j2";
  };
  patches = [
    ./99_framebuffer.patch
    ./0003-arch-arm64-Add-config-option-to-fix-bootloader-cmdli.patch
  ];

  isImageGzDtb = true;
  isModular = false;
}
