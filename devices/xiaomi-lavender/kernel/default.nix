{
  mobile-nixos
, fetchFromGitHub
, ...
}:

#
# Some notes:
#
#  * https://github.com/MiCode/Xiaomi_Kernel_OpenSource/wiki/How-to-compile-kernel-standalone
#
# Things to note:
#
#  * Will not build or boot on all compilers.
#

mobile-nixos.kernel-builder-gcc49 {
  version = "4.4.153";
  configfile = ./config.aarch64;

  # https://github.com/MiCode/Xiaomi_Kernel_OpenSource/tree/lavender-p-oss
  src = fetchFromGitHub {
    owner = "MiCode";
    repo = "Xiaomi_Kernel_OpenSource";
    rev = "1b35cb9e684cbc58867ee44718eb92e7ff951b3a";
    sha256 = "05khzdyk5dlm5zjarjfc5lqzb480g62skp83cirs81lgnyrav8cc";
  };

  patches = [
    ./0001-mobile-nixos-Adds-and-sets-BGRA-as-default.patch
    ./0001-mobile-nixos-Workaround-selected-processor-does-not-.patch
    ./0003-arch-arm64-Add-config-option-to-fix-bootloader-cmdli.patch
  ];

  isImageGzDtb = true;
  isModular = false;
}
