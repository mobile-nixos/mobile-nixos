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

    lib = {
      /* Create a flake configuration with proper cross compilation setup.

        @hostname: defines the hostname of the nixosConfiguration
        @system: defines the system of the target device
        @modules: selects which modules you want to import for the NixOS config
        @outputs: selects which derivations under `config.system.build.*` you want to export as `packages`
      */
      mobileFlake = { hostname, system, modules, outputs }:
        let
          mkMobile = buildSystem: nixpkgs.lib.nixosSystem {
            system = buildSystem;
            inherit modules;
          };

          mkOutput = mobile: output:
            {
              name = "${hostname}_${output}";
              value = mobile.config.system.build.${output};
            };
        in
        {
          nixosConfigurations.${hostname} = mkMobile system;
        } // flake-utils.lib.eachDefaultSystem (buildSystem: {
          packages = builtins.listToAttrs (builtins.map (mkOutput (mkMobile buildSystem)) outputs);
        });
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
