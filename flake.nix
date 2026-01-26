{
  description = "Mobile NixOS - NixOS on mobile devices";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    microhop.url = "github:phodina/microhop/33246f832b2bc214b3b0de747bd0c61fe60cecc0";
  };

  outputs = { self, nixpkgs, microhop }:
    let
      supportedSystems = [ "aarch64-linux" "x86_64-linux" ];

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      packagesForSystem = system:
        let
          microhopOverlay = final: prev: {
            microhop = microhop.packages.${system}.microhop or (throw "microhop package not found in microhop flake");
          };

          overlays = [
            microhopOverlay
            (import ./overlay/overlay.nix)
          ];

          pkgs = import nixpkgs {
            inherit system overlays;
            config.allowUnfree = true;
          };

          devicesDir = ./devices;
          allDeviceNames = builtins.filter
            (name: name != "families" && builtins.pathExists (devicesDir + "/${name}/default.nix"))
            (builtins.attrNames (builtins.readDir devicesDir));

          deviceNames = if system == "x86_64-linux"
            then builtins.filter (name: builtins.match ".*x86_64.*" name != null) allDeviceNames
            else allDeviceNames;

          buildDevice = deviceName:
            nixpkgs.lib.nixosSystem {
              inherit system;
              modules = (import ./modules/module-list.nix) ++ [
                (devicesDir + "/${deviceName}")
                {
                  mobile.enable = true;
                  networking.hostName = deviceName;
                  system.stateVersion = "26.05";

                  nixpkgs = {
                    inherit overlays;
                    config.allowUnfree = true;
                  };
                }
              ];
            };

          devices = builtins.listToAttrs (map (name: {
            name = name;
            value = buildDevice name;
          }) deviceNames);

        in builtins.listToAttrs (
          pkgs.lib.flatten (
            [
              { name = "microhop"; value = microhop.packages.${system}.microhop; }
            ] ++
            (map (deviceName:
              let
                config = devices.${deviceName}.config;
                outputs = config.mobile.outputs;
              in [
                {
                  name = deviceName;
                  value = outputs.default;
                }
                {
                  name = "${deviceName}-system";
                  value = config.system.build.toplevel;
                }
              ]
            ) deviceNames)
          )
        );

      defaultSystem = "aarch64-linux";

      devicesDir = ./devices;
      deviceNames = builtins.filter
        (name: name != "families" && builtins.pathExists (devicesDir + "/${name}/default.nix"))
        (builtins.attrNames (builtins.readDir devicesDir));

      microhopOverlay = final: prev: {
        microhop = microhop.packages.${defaultSystem}.microhop or (throw "microhop package not found in microhop flake");
      };

      overlays = [
        microhopOverlay
        (import ./overlay/overlay.nix)
      ];

      buildDevice = deviceName:
        nixpkgs.lib.nixosSystem {
          system = defaultSystem;
          modules = (import ./modules/module-list.nix) ++ [
            (devicesDir + "/${deviceName}")
            {
              mobile.enable = true;
              networking.hostName = deviceName;
              system.stateVersion = "25.11";

              nixpkgs = {
                inherit overlays;
                config.allowUnfree = true;
              };
            }
          ];
        };

      devices = builtins.listToAttrs (map (name: {
        name = name;
        value = buildDevice name;
      }) deviceNames);

    in {
      nixosConfigurations = devices;

      packages = forAllSystems (system: packagesForSystem system);
    };
}
