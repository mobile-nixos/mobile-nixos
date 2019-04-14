{
  mobile-nixos
, fetchFromGitHub
, kernelPatches ? [] # FIXME
, dtbTool
}:

(mobile-nixos.kernel-builder-gcc6 {
  version = "3.10.108";
  configfile = ./config.aarch64;
  dtb = "unknown";
  #file = "vmlinuz-dtb";
  file = "Image.gz";
  src = fetchFromGitHub {
    owner = "LineageOS";
    repo = "android_kernel_asus_msm8916";
    rev = "d56000991e7d90e3a75afd86fb2f3c779232ff29"; # lineage-15.1
    sha256 = "079sm5z0ml0ijm866ga5mzwnix4wzvida0469vymbrh8mhz47p4r";
  };

  patches = [
    ./0001-Porting-changes-found-in-LineageOS-android_kernel_cy.patch
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
