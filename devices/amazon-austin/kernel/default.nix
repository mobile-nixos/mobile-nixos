{
  mobile-nixos
, fetchFromGitHub
, python2
, buildPackages
, ...
}:

mobile-nixos.kernel-builder-gcc49 {
  version = "3.10.108";
  configfile = ./config.armv7;

  src = fetchFromGitHub {
    # https://forum.xda-developers.com/t/rom-unlocked-ford-austin-lineage-14-1-17-jan-2021.3962457/
    owner = "ggow";
    repo = "android_kernel_amazon_mt8127-common";
    rev = "4045305775d6bbbfaf45fd4f33109937a1eb4057";
    sha256 = "0w9shnxdyvf90h1yzbk5q7m9i0ps3zlwiz760vnv7sbf25kcr746";
  };

  patches = [
    ./90_dtbs-install.patch
    ./0001-mobile-nixos-Could-you-be-more-quiet.patch
  ];

  isImageGzDtb = true;
  isModular = false;

  # mv: cannot stat 'arch/arm/boot/compressed/.head.o.tmp': No such file or directory
  enableParallelBuilding = false;
}
