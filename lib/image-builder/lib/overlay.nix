[
  (self: super: { imageBuilder = self.callPackage ../. {}; })
  # All the software will be upstreamed with NixOS when upstreaming the library.
  (import ../../../overlay/overlay.nix)
]
