{
  description = "Flakes for mobile-nixos";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }: {
    overlay = final: prev: (self.overlays.default final prev) // (self.overlays.mruby-builder final prev);

    overlays = {
      default = import ./overlay/overlay.nix;
      mruby-builder = import ./overlay/mruby-builder/overlay.nix;
    };

    nixosModules =
      let
        supportedDevices = builtins.filter
          (device: builtins.pathExists (./. + "/devices/${device}/default.nix"))
          (builtins.attrNames (builtins.readDir ./devices));

        mkModule = device:
          {
            name = device;
            value = (import ./lib/configuration.nix { inherit device; });
          };
      in
      builtins.listToAttrs (builtins.map mkModule supportedDevices);

  } // flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ self.overlay ];
      };
    in
    {
      legacyPackages = pkgs;
    });
}
