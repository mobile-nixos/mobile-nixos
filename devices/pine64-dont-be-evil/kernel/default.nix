{
  mobile-nixos
, fetchFromGitLab
, kernelPatches ? [] # FIXME
}:

mobile-nixos.kernel-builder {
  version = "5.0.0-rc3-next-20190124";
  configfile = ./config.aarch64;
  dtb = "allwinner/sun50i-a64-dontbeevil.dtb";
  patches = [
    ./dtb-add.patch
  ];
  postPatch = ''
     cp ${./sun50i-a64-dontbeevil.dts} arch/arm64/boot/dts/allwinner/sun50i-a64-dontbeevil.dts
  '';
  src = fetchFromGitLab {
    owner = "pine64-org";
    repo = "linux";
    rev = "ca3ce0ecd672a9fd5ca9419e79769201c4d8697d";
    sha256 = "19izwc3b7cggawlabslrcd2xwmrjna8slbpyy4yp7zf6by377sj9";
  };
}
