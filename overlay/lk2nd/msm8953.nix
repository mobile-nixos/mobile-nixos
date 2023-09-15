{
  stdenv
, fetchFromGitHub
, fetchpatch
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

  patches = [
    (fetchpatch {
      url = "https://patch-diff.githubusercontent.com/raw/msm8953-mainline/lk2nd/pull/35.patch";
      hash = "sha256-6Iqn1K+l0Xek7afb4iTFewoF3SL4uiRBZubc8AE9OSU=";

    })
    (fetchpatch {
      url = "https://patch-diff.githubusercontent.com/raw/msm8953-mainline/lk2nd/pull/36.patch";
      hash = "sha256-hPyqQ5ykhE57gnEBqEOeP7oVigz/JjvTQjDZso2Z3Us=";
    })
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
