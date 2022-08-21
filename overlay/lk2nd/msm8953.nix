{
  stdenv
, fetchFromGitHub
, dtc
, gcc-arm-embedded
, python3
}:
let
  python = (python3.withPackages (p: [
    p.libfdt
  ]));

in stdenv.mkDerivation {
  pname = "lk2nd";
  version = "0.3.1-msm8953-5912c91";

  src = fetchFromGitHub {
    repo = "lk2nd";
    owner = "msm8953-mainline";
    rev = "5912c91e15ed4257f1ec73052328ae66472f7ac7";
    hash = "sha256-HCfqHfEFJ3G3Ou5Zf1Phmp4QpUzxXGcjvz2KXBk9/wc=";
  };

  nativeBuildInputs = [
    gcc-arm-embedded
    dtc
    python
  ];

  postPatch = ''
    patchShebangs --build scripts/{dtbTool,mkbootimg}
  '';

  LD_LIBRARY_PATH = "${python}/lib";

  installPhase = ''
    mkdir -p $out/
    cp ./build-msm8953-secondary/lk2nd.img $out
  '';

  makeFlags = [ "msm8953-secondary" "TOOLCHAIN_PREFIX=arm-none-eabi-" ];

}
