{ mobile-nixos
, fetchFromGitHub
, ...
}:

mobile-nixos.kernel-builder rec {
  version = "5.19.7";
  configfile = ./config.aarch64;

  src = fetchFromGitHub {
    owner = "samueldr";
    repo = "linux";
    rev = "864d93dba25dbc459f235836b954dd644e05ebfb"; # XXX WIP
    hash = "sha256-nui9eFD6GIYWBUhmwoQSLnbIG88P2hpUlPl9b2E/Rrg=";
  };

  patches = [
    ./0001-XXX-google-blueline-sync-dts-with-9060b7256952a63311.patch
    ./0001-touchscreen-focaltech_fts-Add-missing-include.patch
  ];

  isModular = false;
  isCompressed = "gz";
}
