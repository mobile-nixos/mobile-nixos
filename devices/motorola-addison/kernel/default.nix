{
  mobile-nixos
, fetchFromGitHub
, kernelPatches ? [] # FIXME
, dtbTool
}:

(mobile-nixos.kernel-builder-gcc6 {
  version = "3.18.71";
  configfile = ./config.aarch64;

  file = "Image.gz";
  hasDTB = true;

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
  ];

  isModular = false;

}).overrideAttrs({ postInstall ? "", postPatch ? "", ... }: {
  installTargets = [ "zinstall" ];
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
    ${dtbTool}/bin/dtbTool -s 2048 -p "scripts/dtc/" -o "$out/dtbs/motorola-addison.img" "$out/dtbs/qcom/"
  '';
})
