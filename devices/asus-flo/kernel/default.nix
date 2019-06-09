{
  mobile-nixos
, fetchFromGitHub
, kernelPatches ? [] # FIXME
}:

(mobile-nixos.kernel-builder-gcc6 {
  version = "3.4.113";
  configfile = ./config.armv7;
  #file = "vmlinuz-dtb";
  file = "zImage";
  src = fetchFromGitHub {
    owner = "LineageOS";
    repo = "android_kernel_google_msm";
    rev = "a4b9cf707b9acf6e5f6089d1121ae973efe399b0";
    sha256 = "0q88sqmcd09m0wq27rvzvq588gbk3daji1zp36qpyzl1d66b37v6";
  };

  patches = [
    ./00_fix_return_address.patch
    ./02_gpu-msm-fix-gcc5-compile.patch
    ./03-fix-video-argb-setting.patch
    ./patch_fsp_detect.patch
    ./patch_lifebook_detect.patch
    ./90_dtbs-install.patch
    ./99_framebuffer.patch
  ];

  isModular = false;

}).overrideAttrs({ postInstall ? "", postPatch ? "", ... }: {
  installTargets = [ "zinstall" ];
  postPatch = postPatch + ''
    cp -v "${./compiler-gcc6.h}" "./include/linux/compiler-gcc6.h"
  '';
  postInstall = postInstall + ''
    mkdir -p "$out/boot"

    # FIXME factor this out properly
    # Copies all potential output files.
    for f in zImage-dtb Image.gz-dtb zImage Image.gz Image; do
      f=arch/arm/boot/$f
      [ -e "$f" ] || continue
      echo "zImage found: $f"
      cp -v "$f" "$out/"
      break
    done

    mkdir -p $out/dtb
    for f in arch/*/boot/dts/*.dtb; do
      cp -v "$f" $out/dtb/
    done

  '';
})
