final: super: {
  pine64-pinephone = {
    qfirehose = final.callPackage ./qfirehose {};
  };

  crustFirmware = final.callPackage ./crust-firmware {
    inherit (final.buildPackages)
      stdenv
      flex
      yacc
    ;

    or1k-toolchain = final.pkgsCross.or1k.buildPackages;
  };
}
