final: super: {
  crustFirmware = final.callPackage ./crust-firmware {
    inherit (final.buildPackages)
      stdenv
      flex
      yacc
    ;

    or1k-toolchain = final.pkgsCross.or1k.buildPackages;
  };
}
