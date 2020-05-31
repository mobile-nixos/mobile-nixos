{
  mobile-nixos
, stdenv
, hostPlatform
, fetchFromGitHub
, kernelPatches ? [] # FIXME
, dtbTool
}:

#
# Note:
# This kernel build is special, it supports both armv7l and aarch64.
# This is because motorola ships an armv7l userspace from stock ROM.
#
# in local.nix:
#  mobile.system.system = lib.mkForce "armv7l-linux";
#

let
  inherit (stdenv.lib) optionalString;
  cpuName = hostPlatform.parsed.cpu.name;
in
(mobile-nixos.kernel-builder-gcc6 {
  version = "3.18.71";
  configfile = ./. + "/config.${cpuName}";

  file = if (cpuName == "aarch64") then "Image.gz" else "zImage";
  hasDTB = (cpuName == "aarch64");

  src = fetchFromGitHub {
    owner = "LineageOS";
    repo = "android_kernel_motorola_msm8953";
    rev = "80530de6e297dd0f0ba479c0dcc4ddb7c9e90e24"; # lineage-15.1
    sha256 = "0qw8x61ycpkk5pqvs9k2abr5lq56ga5dml6vkygvmi8psm2g6kg1";
  };

  patches = [
    ./04_fix_camera_msm_isp.patch
    ./05_misc_msm_fixes.patch
    ./06_prima_gcc6.patch
    ./99_framebuffer.patch
    ./0001-Allow-building-WCD9335_CODEC-without-REGMAP_ALLOW_WR.patch
    ./0005-Allow-building-with-sound-disabled.patch
    ./0006-Fix-missing-include-in-epl8802-driver.patch
    ./0007-switch-mmc1-card-detect-sense.patch
  ];

  isModular = false;

}).overrideAttrs({ postInstall ? "", postPatch ? "", ... }: {
  installTargets = [ "zinstall" "dtbs" ];
  postPatch = postPatch + ''
    cp -v "${./compiler-gcc6.h}" "./include/linux/compiler-gcc6.h"

    # FIXME : factor out
    (
    # Remove -Werror from all makefiles
    local i
    local makefiles="$(find . -type f -name Makefile)
    $(find . -type f -name Kbuild)"
    for i in $makefiles; do
      sed -i 's/-Werror-/-W/g' "$i"
      sed -i 's/-Werror=/-W/g' "$i"
      sed -i 's/-Werror//g' "$i"
    done
    )
  '';
  postInstall = postInstall + ''
    mkdir -p "$out/dtbs/"
  ''
  + optionalString (cpuName == "aarch64") ''
    ${dtbTool}/bin/dtbTool -s 2048 -p "scripts/dtc/" -o "$out/dtbs/motorola-potter.img" "$out/dtbs/qcom/"
  ''
  + optionalString (cpuName == "armv7l") ''
     ${dtbTool}/bin/dtbTool -s 2048 -p "scripts/dtc/" -o "$out/dtbs/motorola-potter.img" "arch/arm/boot"
  ''
  ;
})
