# This file is used to flattenize release.nix for `nix-env` use.
# In turn, this is used by the CI steps for validating the evaluation is still
# working fine, and to get a list of diffs for the changes.
let
  # Evaluate release.nix
  release = import ../release.nix {
    systems = [ "aarch64-linux" "x86_64-linux" ];
  };

  # Get "a" Nixpkgs for its lib.
  pkgs = import <nixpkgs> {};
  inherit (pkgs) lib;
  # And import what we need in scope.
  inherit (lib.attrsets) getAttrFromPath nameValuePair mapAttrs' mapAttrsToList;
  inherit (lib.strings) splitString;
  inherit (lib.lists) flatten;

  # Given a path, returns the attrset at that path in release,
  # with the attribute names prefixed with path.
  dig = dig' release;

  # Given a path, returns the attrset at that path in attrset,
  # with the attribute names prefixed with path.
  dig' = attrset: path:
    mapAttrs' (name: value: nameValuePair "${path}.${name}" value)
    (getAttrFromPath (splitString "." path) attrset)
  ;

  # Flattened attrset of device builds.
  devices =
    let
      # Listifies devices in a list of lists of nameValuePairs.
      # This will be flattened and re-hydrated in a shallow attrset.
      devicesList =
        mapAttrsToList
        (deviceName: list: mapAttrsToList (platformName: value: {
            name = "device.${deviceName}.${platformName}";
            value = value;
          }) list)
        release.device
      ;
    in
      builtins.listToAttrs (flatten devicesList)
    ;

  flattened =
    # If this fails, evaluations probably don't receive additional configuration
    # configuring nixpkgs.localSystem.
    assert devices."device.asus-z00t.aarch64-linux" != devices."device.asus-z00t.x86_64-linux";
    release //
    devices //
    # We could try and do something smart to unwrap two levels of attrsets
    # automatically, but by stating we want those paths we are ensuring that
    # they are still present in the attrsets.
    (dig "examples-demo.aarch64-linux") //
    (dig "overlay.aarch64-linux.aarch64-linux") //
    (dig "overlay.x86_64-linux.aarch64-linux-cross") //
    (dig "overlay.x86_64-linux.armv7l-linux-cross") //
    (dig "overlay.x86_64-linux.x86_64-linux")
  ;

  # Escape the name so `nix-env` will show it.
  escapeName = builtins.replaceStrings ["."] ["++"];
in
  mapAttrs'
  (name: value: nameValuePair (escapeName name) value)
  flattened
