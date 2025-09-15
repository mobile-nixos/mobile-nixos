{ pkgs ? null }: 

if pkgs == null then (builtins.throw "The `pkgs` argument needs to be provided to release-tools.nix") else
let
  # Original `evalConfig`
  evalConfig = import "${toString pkgs.path}/nixos/lib/eval-config.nix";
  inherit (pkgs.lib)
    filterAttrsRecursive
    getAttrFromPath
    isAttrs
    isDerivation
    isList
    last
    mapAttrsRecursive
  ;
in
rec {
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
    inherit (pkgs) system;
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

  # These can rely freely on lib, avoid depending on pkgs.
  withPkgs = pkgs:
    let
      inherit (pkgs) lib;
    in
    rec {
      specialConfig = {name, buildingForSystem, system, config ? {}}: {
        special = true;
        inherit name;
        config = {
          imports = [
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
      };

      # Shortcuts from a simple system name to the structure required for
      # localSystem and crossSystem
      knownSystems = {
        x86_64-linux  = lib.systems.examples.gnu64;
        aarch64-linux = lib.systems.examples.aarch64-multiplatform;
        armv7l-linux  = lib.systems.examples.armv7l-hf-multiplatform;
      };

      # Eval with a configuration, for the given device.
      evalWithConfiguration = configuration: device: evalWith {
        modules = [ configuration ];
        inherit device;
      };

      # The simplest eval for a device, with an empty configuration.
      evalFor = evalWithConfiguration {};
    };

  # Given an overlay, and an attrset faking some needed attributes (as workarounds),
  # will produce an attrset with null values.
  # Use the result with `mapAttrsRecursive` to evaluate the overlay attributes.
  readOverlayAttributeNames =
    workarounds: overlay:
    let
      overlayAttrs = builtins.attrNames (overlay {} {});
      bogusPkgs =
        rec {
          __tarpit = _: __tarpit; /* tarpit to allow type-checking */
          callPackage = expr: args:
            bogusPkgs.__tarpit
          ;
          overrideScope = arg:
            let
              scopeAttrs = builtins.attrNames (self);
              super =
                bogusPkgs
                // (builtins.listToAttrs (builtins.map (name: { inherit name; value = super; }) scopeAttrs))
              ;
              self = arg self super;
            in
              self
          ;
          overrideAttrs = __tarpit;
          pkgsStatic = bogusPkgs;
        }
        // (builtins.listToAttrs (builtins.map (name: { inherit name; value = bogusPkgs; }) overlayAttrs))
        // (workarounds bogusPkgs)
      ;
      blockedAttributes =
        filterAttrsRecursive
        (_: v: v == false)
        bogusPkgs
      ;
    in
    (
      mapAttrsRecursive
      (path: value: null)
      (
        filterAttrsRecursive
        (name: value: name != "recurseForDerivations" && value != false)
        ((overlay bogusPkgs bogusPkgs) // blockedAttributes)
      )
    )
  ;

  recurseIntoPackageSet =
    { path ? [], packageset, eval }:
    (
      if path == []
      then mapAttrsRecursive
      else builtins.mapAttrs
    )
    (
      path': _:
      let
        currPath = path ++ (
          if isList path'
          then path'
          else [ path' ]
        );
        value = getAttrFromPath currPath eval.pkgs;
        name = last currPath;
      in
      if name == "recurseForDerivations" || value == null || value == false
      then null
      else
      if (isDerivation value)
      then currPath
      else
        if isAttrs value && value ? recurseForDerivations && value.recurseForDerivations
        then (
          recurseIntoPackageSet {
            path = currPath;
            packageset = value;
            inherit eval;
          }
        )
        else null
    )
    packageset
  ;
}
