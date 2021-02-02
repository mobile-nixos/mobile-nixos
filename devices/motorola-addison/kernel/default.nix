{
  mobile-nixos
, stdenv
, fetchFromGitHub
, ...
}:

#
# Note:
# This kernel build is special, it supports both armv7l and aarch64.
# This is because motorola ships an armv7l userspace from stock ROM.
#
# in local.nix:
#  mobile.system.system = lib.mkForce "armv7l-linux";
#

mobile-nixos.kernel-builder-gcc6 {
  version = "3.18.71";
  configfile = ./. + "/config.${stdenv.hostPlatform.parsed.cpu.name}";

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
  ];

  enableRemovingWerror = true;
  isModular = false;
  isQcdt = true;
}
