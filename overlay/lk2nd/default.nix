{
  stdenv
, fetchFromGitHub
, fetchpatch
, dtc
, gcc-arm-embedded
, python3
, soc ? null
}:
let
  python = (python3.withPackages (p: [
    p.libfdt
  ]));
  version = "22.0";

in stdenv.mkDerivation {
  pname = "lk2nd";
  inherit version;

  src = fetchFromGitHub {
    repo = "lk2nd";
    owner = "msm8916-mainline";
    rev = version;
    hash = "sha256-PCpOWwBUkcRn6KTJTJ7UiVcpGt67qP2dLhlcplKNOo0=";
  };

  nativeBuildInputs = [
    gcc-arm-embedded
    dtc
    python
  ];

  patches = [
    ./extlinux-enlarge-ramdisk.patch
  ];

  postPatch = ''
    PATH=${python}/bin/:$PATH patchShebangs lk2nd/scripts/{dtbTool,mkbootimg}
  '';

  LD_LIBRARY_PATH = "${python}/lib";

  installPhase = ''
    mkdir $out
    cp ./build-lk2nd-${soc}/lk2nd.img $out
  '';

  makeFlags = [
    "lk2nd-${soc}"
    "LD=arm-none-eabi-ld"
    "TOOLCHAIN_PREFIX=arm-none-eabi-"
  ];

}
