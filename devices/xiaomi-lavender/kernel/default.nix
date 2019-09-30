{
  mobile-nixos
, fetchFromGitHub
, kernelPatches ? [] # FIXME
, buildPackages
}:

#
# Some notes:
#
#  * https://github.com/MiCode/Xiaomi_Kernel_OpenSource/wiki/How-to-compile-kernel-standalone
#
# Things to note:
#
#  * The build will not succeed using the `dtc` scripts shipped with their kernel.
#  * Will not build or boot on all compilers.
#

let
  inherit (buildPackages) dtc;
in
(mobile-nixos.kernel-builder-gcc49 {
  version = "4.4.153";
  configfile = ./config.aarch64;

  file = "Image.gz-dtb";
  hasDTB = true;

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

  makeFlags = [
    "DTC_EXT=${dtc}/bin/dtc"
  ];

  isModular = false;

}).overrideAttrs({ postInstall ? "", postPatch ? "", ... }: {
  installTargets = [ "zinstall" "Image.gz-dtb" "install" ];
  postInstall = postInstall + ''
    cp -v "$buildRoot/arch/arm64/boot/Image.gz-dtb" "$out/"
  '';
})
