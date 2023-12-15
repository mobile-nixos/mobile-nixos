{ mobile-nixos
, fetchFromGitHub
, ...
}:

mobile-nixos.kernel-builder {
  version = "6.2.0";
  configfile = ./config.x86_64;

  src = fetchFromGitHub {
    owner = "torvalds";
    repo = "linux";
    rev = "v6.2";
    sha256 = "sha256-woUP0KZEnwYEzvQEc1OBoCTjkLl8JjYAT4CxFVrfIjU=";
  };

  isModular = false;
  isCompressed = false;
}
