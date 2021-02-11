with (import ./overlay) {};

# A basic shell with some tools available for porting devices.
mkShell rec {
  name = "nixos-mobile";
  buildInputs = [
    # Custom tools
    mobile-nixos.autoport     # Helps users kickstart their ports

    # Third party tools
    dtc                       # For playing around with device tree files
    dtbTool                   # Combines multiple device tree blobs into one image
    file                      # Shows the type of files
    lz4                       # Decompress image files
    mkbootimg                 # Pack and unpack boot images
    python3Packages.binwalk   # Search a binary image for embedded files
    ubootTools                # A couple useful utilities
  ];
}
