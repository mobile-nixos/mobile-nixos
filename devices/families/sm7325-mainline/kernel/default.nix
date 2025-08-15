{
  mobile-nixos,
  fetchFromGitHub,
  ...
}:

# SC7280 is a compute variant of the SM7325
mobile-nixos.kernel-builder {
  version = "6.16.0";
  configfile = ./config.aarch64;

  src = fetchFromGitHub {
    owner = "sc7280-mainline";
    repo = "linux";
    rev = "6cfded7852edc676a16fd61eae38ae030ae9b8f6";
    hash = "sha256-FRMPG/DgvgVhe9CT9GUqC2MnOTSZQbq6FzwWjpjaFs8=";
  };

  patches = [
    ./nothing-spacewar-audio.patch
  ];

  isModular = true;
  isCompressed = "gz";
}
