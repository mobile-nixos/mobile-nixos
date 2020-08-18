# This module, while seemingly having a funny name, has a truthful name.
# It dis(assembles) the integration within the NixOS module system that is
# causing issues for mobile-nixos.
#
# In reality, all fixups made here is a call for a better isolation of the
# modules they target. Let's wait until this is more stable, and add required
# fixes to the NixOS modules system as needed ☺.

{lib, config, ...}:

{
  imports = [
    ./initrd.nix
  ];

  config = lib.mkMerge [
    {
      # I don't know why, but the documentation has issues with the
      # soc options when building other than qemu_x86_64
      # And here the installation-device profile is a bit annoying.
      # Let's ultra-diable the documentation and nixos manual.
      documentation.enable            = lib.mkOverride 10 false;
    }
  ];
}
