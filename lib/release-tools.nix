{ pkgs ? import <nixpkgs> {} }: 

let
  # Original `evalConfig`
  evalConfig = import "${toString pkgs.path}/nixos/lib/eval-config.nix";
in
{
  # This should *never* rely on lib or pkgs.
  all-devices =
    builtins.filter
    (d: builtins.pathExists (../. + "/devices/${d}/default.nix"))
    (builtins.attrNames (builtins.readDir ../devices))
  ;

  # Evaluates NixOS, mobile-nixos and the device config with the given
  # additional modules.
  # Note that we can receive a "special" configuration, used internally by
  # `release.nix` and not part of the public API.
  evalWith =
    { modules
    , device
    , additionalConfiguration ? {}
    , baseModules ? (
      (import ../modules/module-list.nix)
      ++ (import "${toString pkgs.path}/nixos/modules/module-list.nix")
    )
  }: evalConfig {
    inherit baseModules;
    modules =
      (if device ? special
      then [ device.config ]
      else if builtins.isPath device then [ { imports = [ device ]; } ]
      else [ { imports = [(../. + "/devices/${device}")]; } ])
      ++ modules
      ++ [ additionalConfiguration ]
    ;
  };

  # These can rely freely on lib, avoir depending on pkgs.
  withPkgs = pkgs:
    let
      inherit (pkgs) lib;
    in
    rec {
      specialConfig = {name, buildingForSystem, system, config ? {}}: {
        special = true;
        inherit name;
        config = lib.mkMerge [
          config
          {
            mobile.system.type = "none";
            mobile.hardware.soc = {
              x86_64-linux = "generic-x86_64";
              aarch64-linux = "generic-aarch64";
              armv7l-linux = "generic-armv7l";
            }.${buildingForSystem};
            nixpkgs.localSystem = knownSystems.${system};
          }
        ];
      };

      # Shortcuts from a simple system name to the structure required for
      # localSystem and crossSystem
      knownSystems = {
        x86_64-linux  = lib.systems.examples.gnu64;
        aarch64-linux = lib.systems.examples.aarch64-multiplatform;
        armv7l-linux  = lib.systems.examples.armv7l-hf-multiplatform;
      };

      # Given a device compatible with `default.nix`, eval.
      evalFor = evalWithConfiguration {};
      evalWithConfiguration = additionalConfiguration: device:
        import ../. { inherit device additionalConfiguration; }
      ;
    };
}
