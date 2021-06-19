{
  mobile-nixos
, fetchFromGitHub
, python2
, buildPackages
, ...
}:

mobile-nixos.kernel-builder-gcc49 {
  version = "3.10.54";
  configfile = ./config.armv7;

  src = fetchFromGitHub {
    owner = "mobile-nixos";
    repo = "linux";
    rev = "4312630fc893949d7a75075c6ca70a9ccaaefb83";
    sha256 = "165jqyn107bfifqgpizpkp35p72ykfzbsx7bqvh44i3nvhzg2dg7";
  };

  patches = [
    ./90_dtbs-install.patch
  ];

  isImageGzDtb = true;
  isModular = false;

  # mv: cannot stat 'arch/arm/boot/compressed/.head.o.tmp': No such file or directory
  enableParallelBuilding = false;
}
