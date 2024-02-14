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
  version = "0.3.1-msm8916-e7eb070";

  src = fetchFromGitHub {
    repo = "lk2nd";
    owner = "msm8916-mainline";
    rev = "e7eb0707d6ef3723a310bda7962414dac7c9035a";
    hash = "sha256-ZJkEMhNxpJeMleI0x5XWs2rf1oEeLQBPmb8+TtttDtI=";
  };

  nativeBuildInputs = [
    gcc-arm-embedded
    dtc
  ];

  patches = [
    # (fetchpatch {
    #   # this doesn't apply but the same bug needs fixing here
    #   url = "https://patch-diff.githubusercontent.com/raw/msm8953-mainline/lk2nd/pull/35.patch";
    #   hash = "sha256-6Iqn1K+l0Xek7afb4iTFewoF3SL4uiRBZubc8AE9OSU=";

    (fetchpatch {
      url = "https://patch-diff.githubusercontent.com/raw/msm8916-mainline/lk2nd/pull/93.patch";
      hash = "sha256-CTqgy3wXzAAPnCKKU2gn8IswHmI6lQcxsH71hzhN5Yg=";
    })
    ./pstore-msm8916-motorola-harpia.patch

    # })
    # (fetchpatch {
    #   # haven't looked at this one
    #   url = "https://patch-diff.githubusercontent.com/raw/msm8953-mainline/lk2nd/pull/36.patch";
    #   hash = "sha256-hPyqQ5ykhE57gnEBqEOeP7oVigz/JjvTQjDZso2Z3Us=";
    # })
  ];

  postPatch = ''
    PATH=${python}/bin/:$PATH patchShebangs  scripts/{dtbTool,mkbootimg}
    sed -i.bak -e '/compatible/a lk2nd,pstore = <0x9ff00000 0x00100000>; '  dts/msm8916/msm8916-motorola-harpia.dtsi
  '';

  LD_LIBRARY_PATH = "${python}/lib";

  installPhase = ''
    mkdir -p $out/
    cp ./build-lk2nd-msm8916/lk2nd.img $out
  '';

  makeFlags = [
    "lk2nd-msm8916"
    "LD=arm-none-eabi-ld"
    "TOOLCHAIN_PREFIX=arm-none-eabi-"
  ];

}
