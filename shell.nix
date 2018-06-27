with (import ./overlay) {};

# A basic shell with some tools available.
mkShell rec {
  name = "nixos-mobile";
  buildInputs = [
    mkbootimg
    dtbTool
  ];
}
