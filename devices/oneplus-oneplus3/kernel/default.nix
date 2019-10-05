{
  mobile-nixos
, fetchFromGitHub
, kernelPatches ? [] # FIXME
, buildPackages
, dtbTool
}:

(mobile-nixos.kernel-builder-gcc6 {
  configfile = ./config.aarch64;

  file = "Image.gz-dtb";
  hasDTB = true;

  version = "3.18.140";
  src = fetchFromGitHub {
    owner = "android-linux-stable";
    repo = "op3";
    rev = "14eb53941c5374e2300b514b3a860507607404a0";
    sha256 = "1ni2fihmrxj85211k8n2igqgykmw62lc18sn51znm5saccbcz0r7";
  };

  patches = [
    ./99_framebuffer.patch
    ./0001-Imports-drivers-input-changes-from-lineage-16.0.patch
    ./0001-s3320-Workaround-libinput-claiming-kernel-bug.patch
  ];

  isModular = false;

}).overrideAttrs({ postInstall ? "", postPatch ? "", ... }: {
  installTargets = [ "zinstall" "Image.gz-dtb" "install" ];
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
    cp -v "$buildRoot/arch/arm64/boot/Image.gz-dtb" "$out/"
  '';
})
