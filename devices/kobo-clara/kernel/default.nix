{
  mobile-nixos
, fetchFromGitHub
, lzop
, ...
}:

mobile-nixos.kernel-builder {
  version = "5.17.9";
  configfile = ./config.armv7l;

  src = fetchFromGitHub {
    owner = "akemnade";
    repo = "linux";
    rev = "ad6a7e9da33a3c6dd317420728dd2b0ea16716f8";
    sha256 = "sha256-JTNJTLq2L2zVeJkSQuhmSYii3m5MnlGuSIw60wDnqcg=";
  };

  nativeBuildInputs = [ lzop ];
}
