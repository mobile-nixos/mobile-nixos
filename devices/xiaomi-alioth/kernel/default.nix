{ mobile-nixos
, fetchFromGitHub
, buildPackages
, ...
}:

let
  # This port starts from the pmaports sm8250 alioth config.  Mobile NixOS'
  # generic config validator currently assumes many options are built-in or
  # disabled in ways that conflict with that known-working modular config.
  kernelBuilder = mobile-nixos.kernel-builder.override {
    systemBuild-structuredConfig = _: {};
  };
  modDirVersion = "6.15.1-sm8250";
in
kernelBuilder {
  version = "6.15.1";
  inherit modDirVersion;
  configfile = ./config.aarch64;

  src = fetchFromGitHub {
    owner = "mainlining";
    repo = "linux";
    rev = "nikroks/alioth";
    hash = "sha256-aMo5zbgeLWgCAHcWgM6v/hEJ+5sLW/P4gH6HE+bY/Og=";
  };

  isModular = true;
  isCompressed = "gz";

  nativeBuildInputs = [
    buildPackages.python3
    buildPackages.zstd
  ];

  postInstall = ''
    if [ -d "$out/lib/modules/${modDirVersion}" ]; then
      echo ":: Running depmod for ${modDirVersion}"
      ${buildPackages.kmod}/bin/depmod -b "$out" -a "${modDirVersion}"
    fi
  '';
}
