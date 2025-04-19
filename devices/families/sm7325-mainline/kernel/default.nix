{
  mobile-nixos
, fetchFromGitHub
, ...
}:

# SC7280 is a compute variant of the SM7325
mobile-nixos.kernel-builder {
  version = "6.14.0";
  configfile = ./config.aarch64;

  src = fetchFromGitHub {
    owner = "sc7280-mainline";
    repo = "linux";
    rev = "dc5c84afbf87c184bc866e328c502b7e0bcaa0f1";
    hash = "sha256-A6Ne09Hjx44B0IHSjZuxjrTjCl5wxJ1j1+Wk9G2NOS8=";
  };

  isModular = true;
  isCompressed = "gz";
}
