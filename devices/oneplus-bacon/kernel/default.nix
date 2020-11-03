{
  mobile-nixos
, fetchFromGitHub
, kernelPatches ? [] # FIXME
, buildPackages
, ...
}:

(mobile-nixos.kernel-builder-gcc6 {
  configfile = ./config.armv7l;
#  configfile = ./config-postmarketos-qcom-msm8974.armv7;

#  version = "5.11.6";
#  src = fetchgit {
#    url = "https://gitlab.com/postmarketOS/linux-postmarketos.git";
#    rev = "2b0c6af3cb824787bfb8ae65013b02696e9df439";
#    sha256 = "sha256-0OBmU6TYnf034pZazePeod5Blyz0krfp6xNk+NL3hxQ=";
#  };
  version = "3.4.113";

  src = fetchFromGitHub {
    owner = "LineageOS";
    repo = "android_kernel_oppo_msm8974";
    rev = "2c3e149a9e55fa68f34362a9973c85b0e395c381"; # lineageos-18.1
    sha256 = "sha256-p2Nf6V+zhEwVGDljC1A2HSnoaYwBZJmCIVtBdUyffoQ=";
  };
  patches = [
    ./0001-fix-video-argb-setting.patch
    ./02_gpu-msm-fix-gcc5-compile.patch
    ./mdss_fb_refresh_rate.patch
    ./05-sysctl-add-missing-NET_IPV6_ACCEPT_RA_PREFIX_ROUTE.patch
    #./0003-arch-arm-Add-config-option-to-fix-bootloader-cmdli.patch
    ./90_dtbs-install.patch
    ./99_framebuffer.patch
  ];

  enableRemovingWerror = true;
  enableCompilerGcc6Quirk = true;
  #isCompressed = true;
  isQcdt = true;
  enableParallelBuilding=false; # fixdep: error opening depfile: arch/arm/boot/compressed/.lib1funcs.o.d: No such file or directory
  isImageGzDtb = true;
  isModular = false;

}).overrideAttrs({ postInstall ? "", ... }@o: {
  preConfigure = ''
    makeFlagsArray+=("CONFIG_NO_ERROR_ON_MISMATCH=y")
    buildFlagsArray+=("CONFIG_NO_ERROR_ON_MISMATCH=y")
  '';
})
