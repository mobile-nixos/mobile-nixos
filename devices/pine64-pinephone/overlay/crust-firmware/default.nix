{ stdenv, lib, fetchFromGitHub
, flex, yacc, or1k-toolchain }:

stdenv.mkDerivation rec {
  pname = "crust-firmware";
  version = "0.3";

  src = fetchFromGitHub {
    owner = "crust-firmware";
    repo = "crust";
    rev = "v${version}";
    sha256 = "1ncn2ncmkj1cjk68zrgr5yk7b9x1xxcrcmk9jf188svjgk0cq2m5";
  };

  depsBuildBuild = [
    stdenv.cc
  ];

  nativeBuildInputs = [
    flex
    yacc
  ] ++ (with or1k-toolchain; [
    binutils
    gcc
  ]);

  postPatch = ''
    substituteInPlace Makefile --replace "= lex" '= ${flex}/bin/flex'
  '';

  buildPhase = ''
    export CROSS_COMPILE=or1k-elf-
    export HOST_COMPILE=${stdenv.cc}/bin/${stdenv.cc.bintools.targetPrefix}

    make pinephone_defconfig
    make scp
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp -v build/scp/scp.bin $out
  '';

  meta = with lib; {
    description = "Libre SCP firmware for Allwinner sunxi SoCs";
    homepage = "https://github.com/crust-firmware/crust";
    license = with licenses; [ bsd3 gpl2Only mit ];
    maintainers = [ maintainers.noneucat ];
    platforms = platforms.all;
  };
}

