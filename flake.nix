{
  description = "Flakes for mobile-nixos";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }: let

    buildSystems = [ "aarch64-linux" "x86_64-linux" ];

  in {
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
      */
      mobileFlake = { hostname, system, modules }:
        let
          mkMobile = buildSystem: nixpkgs.lib.nixosSystem {
            system = buildSystem;
            inherit modules;
          };
        in
        {
          nixosConfigurations.${hostname} = mkMobile system;
        } // flake-utils.lib.eachSystem buildSystems (buildSystem: {
          packages = with nixpkgs.lib;
            let
              eval = mkMobile buildSystem;

              potentialOutputs = eval.config.mobile.outputs // eval.config.mobile.outputs.${eval.config.mobile.system.type};
              actualOutputs = filterAttrs (_key: isDerivation) potentialOutputs;
            in
              mapAttrs'
                (key: nameValuePair ("${hostname}_${key}"))
                actualOutputs;

          defaultPackage = (mkMobile buildSystem).config.mobile.outputs.default;
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

  } // flake-utils.lib.eachSystem buildSystems (system: {
    # shell.nix is already applying the overlay, so we do not need to import them ourself
    devShell = import ./shell.nix { pkgs = import nixpkgs { inherit system; }; };

    legacyPackages = import nixpkgs { inherit system; overlays = [ self.overlay ]; };
  });
}
