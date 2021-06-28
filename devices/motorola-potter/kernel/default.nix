{
  mobile-nixos
, stdenv
, fetchFromGitHub
, ...
}:


mobile-nixos.kernel-builder-gcc6 {
  version = "3.18.140";
  configfile = ./config.aarch64;

  src = fetchFromGitHub {
    owner = "boulzordev";
    repo = "android_kernel_motorola_msm8953";
    rev = "32b6f05688ff51e54958a8e97df24cd63a62b880";
    sha256 = "0r0xkf6cq60bvckn311k43yxrm0qjp9psi6g3jfc6l5z4k549glm";
  };

  patches = [
    ./04_fix_camera_msm_isp.patch
    ./99_framebuffer.patch
    ./0001-Allow-building-WCD9335_CODEC-without-REGMAP_ALLOW_WR.patch
    ./0005-Allow-building-with-sound-disabled.patch
    ./0007-Coalesce-identical-device-trees.patch
    ./0008-Notify-clients-when-FB-opened.patch
  ];

  enableRemovingWerror = true;
  isModular = false;
  isQcdt = true;
}
