{
  mobile-nixos
, fetchFromGitHub
, ...
}:

mobile-nixos.kernel-builder-gcc6 {
  version = "3.4.113";
  configfile = ./config.armv7;

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

  enableCompilerGcc6Quirk = true;
  isModular = false;

  # mv: cannot stat 'arch/arm/boot/compressed/.misc.o.tmp': No such file or directory
  enableCombiningBuildAndInstallQuirk = false;
}
