{ mobile-nixos
, fetchFromGitHub
, ...
}:

let hashes = {
      "6.6.10" = { # 6.6.10/main
        rev = "93e9c753f72e31193c0d29f673b7ed18de155af0";
        hash = "sha256-4CRjk5ojjMVhy4wqoGcqsP7FYkQ2A4F3YV7yEqCk8jM=";
      };
      "6.5.2" = { # 6.5.2/ipa
        rev = "e7797492485f14684f5575f82800d09508df2034";
        hash = "sha256-iJl4+2W96IlBiWiSq58ZAWgO3L3wNmuNLbmkCjCID1Y=";
      };
    };
    version = "6.6.10";
in mobile-nixos.kernel-builder {
  inherit version;
  configfile = ./config.aarch64;

  src = fetchFromGitHub {
    owner = "msm8953-mainline";
    repo = "linux";
    inherit (hashes.${version}) rev hash;
  };

  patches = [
    # ./random-msm-bindings-fixes.patch # already in 6.6.10
  ];

  isModular = true;
}
