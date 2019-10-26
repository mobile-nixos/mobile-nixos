with (import ./overlay) {};

# A basic shell with some tools available.
mkShell rec {
  name = "nixos-mobile";
  buildInputs = [
    dtbTool
    file
    lz4
    mkbootimg
    python3Packages.binwalk
  ];
}
