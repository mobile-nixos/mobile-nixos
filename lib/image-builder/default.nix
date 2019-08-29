{ lib, newScope }:

lib.makeScope newScope (self:
  let
    inherit (self) callPackage;
  in
  {
    makeFilesystem = callPackage ./makeFilesystem.nix {};

    # All known supported filesystems for image generation.
    # Use stand-alone (outside of a disk image) is supported.
    fileSystem = rec {
      makeFAT32 = callPackage ./makeFAT32.nix {};
      # Specialization of `makeFAT32` with (1) filesystemType showing as ESP,
      # and (2) the name defaults to ESP.
      makeESP = args: makeFAT32 ({ name = "ESP"; filesystemType = "ESP"; } // args);
    };

    # All supported disk formats for image generation.
    diskImage = rec {
      makeMBR = callPackage ./makeMBR.nix {};
    };

    # Don't do maths yourselves, just use the helpers.
    # Yes, this is the bibytes family of units.
    size = rec {
      TiB = x: 1024 * (GiB x);
      GiB = x: 1024 * (MiB x);
      MiB = x: 1024 * (KiB x);
      KiB = x: 1024 *      x;
    };
  }
)
