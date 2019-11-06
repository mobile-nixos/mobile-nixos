import (fetchTarball "channel:nixos-19.09") {
  overlays = [(self: super: {
    mobile-nixos-process-doc = self.callPackage ./_support/converter {};
  })];
}
