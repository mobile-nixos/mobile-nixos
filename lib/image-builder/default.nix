{ lib, newScope }:

let
  inherit (lib) makeScope;
in
makeScope newScope (self:
  let
    inherit (self) callPackage;
  in
  # Note: Prefer using `self.something.deep` rather than making `something` a
  # recursive set. Otherwise it won't override as expected.
  {
    makeFilesystem = callPackage ./makeFilesystem.nix {};

    # All known supported filesystems for image generation.
    # Use stand-alone (outside of a disk image) is supported.
    fileSystem = {
      makeExt4 = callPackage ./makeExt4.nix {};
      makeFAT32 = callPackage ./makeFAT32.nix {};
      # Specialization of `makeFAT32` with (1) filesystemType showing as ESP,
      # and (2) the name defaults to ESP.
      makeESP = args: self.fileSystem.makeFAT32 ({ name = "ESP"; filesystemType = "ESP"; } // args);
    };

    gap = length: {
      inherit length;
      isGap = true;
    };

    # All supported disk formats for image generation.
    diskImage = {
      makeMBR = callPackage ./makeMBR.nix {};
      makeGPT = callPackage ./makeGPT.nix {};
    };

    # Don't do maths yourselves, just use the helpers.
    # Yes, this is the bibytes family of units.
    # (This is fine as rec; it won't be overriden.)
    size = rec {
      TiB = x: 1024 * (GiB x);
      GiB = x: 1024 * (MiB x);
      MiB = x: 1024 * (KiB x);
      KiB = x: 1024 *      x;
    };
  }
)
