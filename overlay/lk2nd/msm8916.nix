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

    # support "fastboot oem pstore"
    (fetchpatch {
      url = "https://patch-diff.githubusercontent.com/raw/msm8916-mainline/lk2nd/pull/93.patch";
      hash = "sha256-CTqgy3wXzAAPnCKKU2gn8IswHmI6lQcxsH71hzhN5Yg=";
    })

    # add pstore compatible and reserved-memory node
    ./pstore-msm8916-motorola-harpia.patch

    # this is https://patch-diff.githubusercontent.com/raw/msm8953-mainline/lk2nd/pull/36.patch but applies cleanly
    ./msm8916-ext2-align-blocks.patch
  ];

  postPatch = ''
    PATH=${python}/bin/:$PATH patchShebangs  scripts/{dtbTool,mkbootimg}
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
