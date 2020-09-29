import <nixpkgs> {
  overlays = [(self: super: {
    mobile-nixos-process-doc = self.callPackage ./_support/converter {};
  })];
}
