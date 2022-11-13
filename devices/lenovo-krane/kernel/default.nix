{
  mobile-nixos
, fetchFromGitHub
, fetchpatch
, ...
}:

let
  sdrPatch = rev: sha256: fetchpatch {
    url = "https://github.com/samueldr/linux/commit/${rev}.patch";
    inherit sha256;
  };
in
mobile-nixos.kernel-builder {
  version = "6.0.0";
  configfile = ./config.aarch64;

  src = fetchFromGitHub {
    owner = "torvalds";
    repo = "linux";
    rev = "v6.0";
    sha256 = "sha256-uHNlzGr5NqrvLSRX2hK0kwI0DvvkrbcCNIOg8ro3+94=";
  };

  patches = [
    # arm64: dts: mediatek: kukui: Configure scp firmware filename
    (fetchpatch {
      url = "https://github.com/samueldr/linux/commit/7b624a52f799ab01f36989146de43b0ef51f33fd.patch";
      sha256 = "sha256-gop3rD/vroudrTAbf2hWhBqrTAzRXlWEo22bB1ID0QA=";
    })
  ];

  isModular = false;
  isCompressed = false;
}
