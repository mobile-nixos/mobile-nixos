{
  linuxManualConfig
, fetchFromGitHub
, lzop
, stdenv
, lib
, ...
}:

(linuxManualConfig {
  inherit stdenv lib;
  version = "5.17.9";
  src = fetchFromGitHub {
    owner = "akemnade";
    repo = "linux";
    rev = "ad6a7e9da33a3c6dd317420728dd2b0ea16716f8";
    sha256 = "sha256-JTNJTLq2L2zVeJkSQuhmSYii3m5MnlGuSIw60wDnqcg=";
  };
  configfile = ./config.armv7l;
  config = import ./config.armv7l.nix;
}).overrideAttrs (attrs: {
  nativeBuildInputs = attrs.nativeBuildInputs ++ [ lzop ];
})
