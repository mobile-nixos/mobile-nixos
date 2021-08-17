{
  description = "Flakes for mobile-nixos";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "i686-linux" "aarch64-linux" ];

      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });
    in
    {
      overlay = final: prev: (self.overlays.default final prev) // (self.overlays.mruby-builder final prev);

      overlays = {
        default = import ./overlay/overlay.nix;
        mruby-builder = import ./overlay/mruby-builder/overlay.nix;
      };

      legacyPackages = forAllSystems (system: nixpkgsFor.${system});
    };
}
