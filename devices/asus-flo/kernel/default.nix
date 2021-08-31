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
    rev = "5c4b88269caf1a439440cb98b11c6239f49fc67c";
    sha256 = "1iwhllfpb788hmjivddarg9waqarn7x3kf6glh5qm5brqbyy3vml";
  };

  patches = [
    ./00_fix_return_address.patch
    ./02_gpu-msm-fix-gcc5-compile.patch
    ./03-fix-video-argb-setting.patch
    ./patch_fsp_detect.patch
    ./patch_lifebook_detect.patch
    ./90_dtbs-install.patch
    ./99_framebuffer.patch
    ./0001-Fix-misc.-broken-backports-for-PID_NS-and-USER_NS.patch   
    ./0001-mm-shmem-Fix-incomplete-backport-with-TMPFS_POSIX_AC.patch
  ];

  enableCompilerGcc6Quirk = true;
  isModular = false;

  enableCombiningBuildAndInstallQuirk = true;
  # mv: cannot stat 'arch/arm/boot/compressed/.misc.o.tmp': No such file or directory
  enableParallelBuilding = false;
}
