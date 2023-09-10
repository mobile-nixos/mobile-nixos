{ mobile-nixos
, fetchFromGitHub
, ...
}:

mobile-nixos.kernel-builder {
  version = "6.1.0";
  configfile = ./config.aarch64;

  src = fetchFromGitHub {
    owner = "torvalds";
    repo = "linux";
    rev = "v6.1";
    sha256 = "sha256-7HBzP6P/7KLCfKas4TRFfCutG0azFzV+IpQABtDMHnk=";
  };

  isModular = true;
  isCompressed = false;
}
