# What's release.nix?
# ===================
#
# This is mainly intended to be run by the build farm at the foundation's Hydra
# instance. Though you can use it to run your builds, it is not as ergonomic as
# using `nix-build` on `./default.nix`.
#
# Note:
# Verify that .ci/instantiate-all.nix lists the expected paths when adding to this file.
let
  mobileReleaseTools = (import ./lib/release-tools.nix {});
  inherit (mobileReleaseTools) all-devices;
in
{ mobile-nixos ? builtins.fetchGit ./.
# By default, builds all devices.
, devices ? all-devices
# By default, assume we eval only for currentSystem
, systems ? [ builtins.currentSystem ]
# nixpkgs is also an input, used as `<nixpkgs>` in the system configuration.

# Some additional configuration will be made with this.
# Mainly to work with some limitations (output size).
, inNixOSHydra ? false
}:

let
  # We require some `lib` stuff in here.
  # Pick a lib from the ambient <nixpkgs>.
  pkgs' = import <nixpkgs> {};
  inherit (pkgs') lib releaseTools;
  inherit (mobileReleaseTools.withPkgs pkgs')
    evalFor
    evalWithConfiguration
    knownSystems
    specialConfig
  ;

  # Systems we should eval for, per host system.
  # Non-native will be assumed cross.
  shouldEvalOn = {
    x86_64-linux = [
      "armv7l-linux"
      "aarch64-linux"
      "x86_64-linux"
    ];
    aarch64-linux = [
      "aarch64-linux"
    ];
    armv7l-linux = [
      "armv7l-linux"
    ];
  };

  # Given an evaluated "device", filters `pkgs` down to only our packages
  # unique to the overaly.
  # Also removes some non-packages from the overlay.
  overlayForEval =
    let
      # Trick the overlay in giving us its attributes.
      # Using the values is likely to fail. Thank lazyness!
      overlay = import ./overlay/overlay.nix {} {};
    in
    eval: 
    (lib.genAttrs (builtins.attrNames overlay) (name: eval.pkgs.${name})) //
    {
      # We only "monkey patch" over top of the main nixos one.
      xorg = {
        xf86videofbdev = eval.pkgs.xorg.xf86videofbdev;
      };

      # lib-like attributes...
      # How should we handle these?
      imageBuilder = null;
      kernel-builder = null;
      kernel-builder-gcc49 = null;
      kernel-builder-gcc6 = null;

      # Also lib-like, but a "global" like attribute :/
      defaultKernelPatches = null;
    }
  ;

  # Given a system builds run on, this will return a set of further systems
  # this builds in, either native or cross.
  # The values are `overlayForEval` applied for the pair local/cross systems.
  evalForSystem = system:  builtins.listToAttrs
    (builtins.map (
      buildingForSystem:
      let
        # "device" name for the eval *and* key used for the set.
        name = if system == buildingForSystem then buildingForSystem else "${buildingForSystem}-cross";
        # "device" eval for our dummy device.
        eval = evalFor (specialConfig {inherit name buildingForSystem system;});
        overlay = overlayForEval eval;
      in {
        inherit name;
        value = overlay;
      }) shouldEvalOn.${system}
    )
  ;

  # `device` here is indexed by the system it's being built on first.
  # FIXME: can we better filter this?
  device = lib.genAttrs devices (device:
    lib.genAttrs systems (system:
      (evalWithConfiguration {
        nixpkgs.localSystem = knownSystems.${system};
      } device).build.default
    )
  );

  examples-demo =
    let
      aarch64-eval = import ./examples/demo {
        device = specialConfig {
          name = "aarch64-linux";
          buildingForSystem = "aarch64-linux";
          system = "aarch64-linux";
          config = {
            mobile._internal.compressLargeArtifacts = inNixOSHydra;
            # Do not build kernel and initrd into the system.
            mobile.rootfs.shared.enabled = true;
          };
        };
      };
    in
    {
      aarch64-linux.rootfs = aarch64-eval.build.rootfs;
    };
in
{
  inherit device;
  inherit examples-demo;

  # Overlays build native, and cross, according to shouldEvalOn
  overlay = lib.genAttrs systems (system:
    (evalForSystem system)
  );

  tested = let
    hasSystem = name: lib.lists.any (el: el == name) systems;

    constituents =
      lib.optionals (hasSystem "x86_64-linux") [
        device.uefi-x86_64.x86_64-linux              # UEFI system
        # Cross builds
        device.asus-z00t.x86_64-linux                # Android
        device.asus-dumo.x86_64-linux                # Depthcharge
      ]
      ++ lib.optionals (hasSystem "aarch64-linux") [
        device.asus-z00t.aarch64-linux               # Android
        device.asus-dumo.aarch64-linux               # Depthcharge
        examples-demo.aarch64-linux.rootfs
      ];
  in
  releaseTools.aggregate {
    name = "mobile-nixos-tested";
    inherit constituents;
    meta = {
      description = "Representative subset of devices that have to succeed.";
    };
  };
}
