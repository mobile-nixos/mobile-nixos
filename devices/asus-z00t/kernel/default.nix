{
  mobile-nixos
, fetchFromGitHub
, kernelPatches ? [] # FIXME
, dtbTool
}:

(mobile-nixos.kernel-builder-gcc6 {
  version = "3.10.108";
  configfile = ./config.aarch64;

  file = "Image.gz";
  hasDTB = true;

  src = fetchFromGitHub {
    owner = "LineageOS";
    repo = "android_kernel_asus_msm8916";
    rev = "1a45c63742b8c3253a38c2ff97b672918c88d8df"; # lineage-15.1
    sha256 = "02mfz3h5s3lvkdinglqmhm2hyfw4w0hqzzh1xla1i9wfc31ddbap";
  };

  patches = [
    ./0001-Porting-changes-found-in-LineageOS-android_kernel_cy.patch
    ./01_more_precise_arch.patch
    ./01_fix_gcc6_errors.patch
    ./02_mdss_fb_refresh_rate.patch
    ./05_dtb-fix.patch
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
    ${dtbTool}/bin/dtbTool -s 2048 -p "scripts/dtc/" -o "arch/arm64/boot/asus-z00t.img" "arch/arm/boot/"
    cp "arch/arm64/boot/asus-z00t.img" "$out/dtbs/asus-z00t.img"

    mkdir -p $out/dtb
    for f in arch/*/boot/dts/*.dtb; do
      cp -v "$f" $out/dtb/
    done

#    # FIXME: understand the specifics of why this needs to be catted together.
#    (
#    cd $out
#    cat Image.gz dtb/*.dtb > vmlinuz-dtb
#    )
  '';
})
