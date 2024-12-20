# What's release.nix?
# ===================
#
# This is mainly intended to be run by the build farm at the foundation's Hydra
# instance. Though you can use it to run your builds, it is not as ergonomic as
# using `nix-build` on `./default.nix`.
#
# Also note that *by design* it still relies on NIX_PATH being used for the
# input Nixpkgs.
#
# Note:
# Verify that .ci/instantiate-all.nix lists the expected paths when adding to this file.

{ mobile-nixos ? builtins.fetchGit ./.
# By default, builds all devices.
, devices ? null

# By default, assume we eval only for this eval's system
, systems ? null

# Some additional configuration will be made with this.
# Mainly to work with some limitations (output size).
, inNixOSHydra ? false

# The current system, for pure evals it must be provided.
, system ? null

# The Nixpkgs this release is evaluated with.
# By default relies on the pinned Nixpkgs.
, pkgs ? null
}@args':

let
  system =
    if args' ? system
    then (args'.system)
    else builtins.currentSystem
  ;
  systems =
    if args' ? systems
    then args'.systems
    else [ system ];
  pkgs =
    if args' ? pkgs
    then
      if args' ? system
      then builtins.throw "Providing the `system` argument when providing your own `pkgs` is forbidden. You should instead pass the desired `system` argument to your `pkgs` instance."
      else (args'.pkgs)
    else (import ./pkgs.nix { inherit system; })
  ;

  mobileReleaseTools = (import ./lib/release-tools.nix { inherit pkgs; });
in

# This weird shuffle is to make the `device` argument depend on the input `pkgs`,
# while also keeping the original `devices` argument name in the code..
let devices' = devices; in
let
  devices =
    if devices' == null
    then mobileReleaseTools.all-devices
    else devices'
  ;
in
# Drop this unneeded name.
let devices' = null; in

let
  # We require some `lib` stuff in here.
  # Pick a lib from the arbitrary package set.
  inherit (pkgs) lib releaseTools;
  inherit (mobileReleaseTools.withPkgs pkgs)
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

  onlyDerivations = lib.filterAttrs (k: v: lib.isDerivation v);
  onlyDerivationsAndAttrsets = lib.filterAttrs (k: v: lib.isDerivation v || (lib.isAttrs v && !lib.isFunction v));

  # Given an evaluated "device", filters `pkgs` down to only our packages
  # unique to the overaly.
  # Also removes some non-packages from the overlay.
  overlayForEval =
    let
      # Trick the overlay in giving us its attributes.
      # Using the values is likely to fail. Thank lazyness!
      overlayAttrNames = builtins.attrNames (import ./overlay/overlay.nix {} {});
    in
    eval: let overlay = (lib.genAttrs overlayAttrNames (name: eval.pkgs.${name})); in
    overlay // {
      # We only "monkey patch" over top of the main nixos one.
      xorg = {
        xf86videofbdev = eval.pkgs.xorg.xf86videofbdev;
      };

      # lib-like attributes...
      # How should we handle these?
      image-builder = null;
      mobile-nixos = (onlyDerivationsAndAttrsets overlay.mobile-nixos) // {
        # The cross canaries attrsets will be used as constituents.
        # Filter out `override` and `overrideAttrs` early.
        cross-canary-test = onlyDerivations overlay.mobile-nixos.cross-canary-test;
        cross-canary-test-static = onlyDerivations overlay.mobile-nixos.cross-canary-test-static;
      };

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
      } device).config.mobile.outputs.default
    )
  );

  # `kernel` here is indexed by the system it's being built on first.
  # FIXME: can we better filter this?
  kernel = lib.genAttrs devices (device:
    lib.genAttrs systems (system:
      (evalWithConfiguration {
        nixpkgs.localSystem = knownSystems.${system};
      } device).config.mobile.boot.stage-1.kernel.package
    )
  );

  evalExample =
    { example
    , system
    , targetSystem ? system
    }:
    import example {
      inherit pkgs;
      device = specialConfig {
        name =
          if system == targetSystem
          then system
          else "${targetSystem}-built-on-${system}"
        ;
        inherit system;
        buildingForSystem = targetSystem;
        config = {
          # Ensures outputs are digestible by Hydra
          mobile._internal.compressLargeArtifacts = inNixOSHydra;
          # Build a generic rootfs
          mobile.rootfs.shared.enabled = true;
        };
      };
    }
  ;

  evalInstaller =
    { device
    , localSystem
    }:
    let
      eval = evalWithConfiguration {
        imports = [
          ./examples/installer/configuration.nix
        ];
        nixpkgs.localSystem = knownSystems.${localSystem};
      } device;
    in
      eval // { inherit (eval.config.mobile) outputs; }
  ;

  doc = import ./doc {
    inherit pkgs;
  };
in
rec {
  inherit device;
  inherit kernel;
  inherit doc;
  shell = import ./shell.nix { inherit pkgs; };

  # Some example systems to build.
  # They track breaking changes, and ensures dependencies are built.
  # They may or may not work as-they-are on devices. YMMV.
  examples = {
    hello = {
      x86_64-linux.toplevel  = (evalExample { example = ./examples/hello; system = "x86_64-linux"; }).outputs.toplevel;
      aarch64-linux.toplevel = (evalExample { example = ./examples/hello; system = "aarch64-linux"; }).outputs.toplevel;
      cross-x86-aarch64.toplevel = (evalExample { example = ./examples/hello; system = "x86_64-linux"; targetSystem = "aarch64-linux"; }).outputs.toplevel;
      cross-x86-armv7l.toplevel  = (evalExample { example = ./examples/hello; system = "x86_64-linux"; targetSystem = "armv7l-linux";  }).outputs.toplevel;
    };
    phosh = {
      x86_64-linux.toplevel  = (evalExample { example = ./examples/phosh; system = "x86_64-linux"; }).outputs.toplevel;
      aarch64-linux.toplevel = (evalExample { example = ./examples/phosh; system = "aarch64-linux"; }).outputs.toplevel;
      cross-x86-aarch64.toplevel = (evalExample { example = ./examples/phosh; system = "x86_64-linux"; targetSystem = "aarch64-linux"; }).outputs.toplevel;
    };
    plasma-mobile = {
      x86_64-linux.toplevel  = (evalExample { example = ./examples/plasma-mobile; system = "x86_64-linux"; }).outputs.toplevel;
      aarch64-linux.toplevel = (evalExample { example = ./examples/plasma-mobile; system = "aarch64-linux"; }).outputs.toplevel;
      cross-x86-aarch64.toplevel = (evalExample { example = ./examples/plasma-mobile; system = "x86_64-linux"; targetSystem = "aarch64-linux"; }).outputs.toplevel;
    };
  };

  installer = {
    lenovo-krane = (evalInstaller { device = "lenovo-krane"; localSystem = "aarch64-linux"; }).outputs.default;
    lenovo-wormdingler = (evalInstaller { device = "lenovo-wormdingler"; localSystem = "aarch64-linux"; }).outputs.default;
    pine64-pinephone = (evalInstaller { device = "pine64-pinephone"; localSystem = "aarch64-linux"; }).outputs.default;
    pine64-pinephonepro = (evalInstaller { device = "pine64-pinephonepro"; localSystem = "aarch64-linux"; }).outputs.default;
  };

  # Overlays build native, and cross, according to shouldEvalOn
  overlay = lib.genAttrs systems (system:
    (evalForSystem system)
  );

  cross-canaries = lib.genAttrs ["aarch64-linux" "armv7l-linux"] (system:
    releaseTools.aggregate {
      name = "cross-canaries-${system}";
      constituents =
        let
          overlay' = overlay.x86_64-linux."${system}-cross";
        in
        (builtins.attrValues overlay'.mobile-nixos.cross-canary-test)
        ++ (builtins.attrValues overlay'.mobile-nixos.cross-canary-test-static)
      ;
      meta = {
        description = "Useful checks for cross-compilation.";
      };
    }
  );

  cross-compiled = {
    installer = {
      lenovo-krane = (evalInstaller { device = "lenovo-krane"; localSystem = "x86_64-linux"; }).outputs.default;
      lenovo-wormdingler = (evalInstaller { device = "lenovo-wormdingler"; localSystem = "x86_64-linux"; }).outputs.default;
      pine64-pinephone = (evalInstaller { device = "pine64-pinephone"; localSystem = "x86_64-linux"; }).outputs.default;
      pine64-pinephonepro = (evalInstaller { device = "pine64-pinephonepro"; localSystem = "aarch64-linux"; }).outputs.default;
    };
  };

  tested = let
    hasSystem = name: lib.lists.any (el: el == name) systems;

    constituents =
      cross-canaries.aarch64-linux.constituents
      ++ lib.optionals (hasSystem "x86_64-linux") [
        device.uefi-x86_64.x86_64-linux              # UEFI system

        # Cross builds
        device.motorola-potter.x86_64-linux          # Android
        device.asus-dumo.x86_64-linux                # Depthcharge

        # Example systems
        examples.hello.x86_64-linux.toplevel
        examples.hello.cross-x86-aarch64.toplevel
        examples.phosh.x86_64-linux.toplevel
        examples.plasma-mobile.x86_64-linux.toplevel

        # Flashable zip binaries are universal for a platform.
        overlay.x86_64-linux.aarch64-linux-cross.mobile-nixos.android-flashable-zip-binaries
      ]
      ++ lib.optionals (hasSystem "aarch64-linux") [
        device.motorola-potter.aarch64-linux         # Android
        device.asus-dumo.aarch64-linux               # Depthcharge

        # Example systems
        examples.hello.aarch64-linux.toplevel
        examples.phosh.aarch64-linux.toplevel
        examples.plasma-mobile.aarch64-linux.toplevel

        installer.pine64-pinephone

        # Flashable zip binaries are universal for a platform.
        overlay.aarch64-linux.aarch64-linux.mobile-nixos.android-flashable-zip-binaries
      ];
  in
  releaseTools.aggregate {
    name = "mobile-nixos-tested";
    inherit constituents;
    meta = {
      description = "Representative subset of devices that have to succeed.";
    };
  };

  # Uses the constituents of tested
  testedPlus = let
    hasSystem = name: lib.lists.any (el: el == name) systems;

    constituents = tested.constituents
      ++ cross-canaries.armv7l-linux.constituents
      ++ lib.optionals (hasSystem "x86_64-linux") [
        # FIXME: add an armv7l system once one is available again
        # device.asus-flo.x86_64-linux
        overlay.x86_64-linux.armv7l-linux-cross.mobile-nixos.android-flashable-zip-binaries
        examples.hello.cross-x86-armv7l.toplevel
      ]
      ++ lib.optionals (hasSystem "aarch64-linux") [
      ]
      ++ lib.optionals (hasSystem "armv7l-linux") [
        # FIXME: add an armv7l system once one is available again
        # device.asus-flo.armv7l-linux
        overlay.armv7l-linux.armv7l-linux.mobile-nixos.android-flashable-zip-binaries
      ]
      ;
  in
  releaseTools.aggregate {
    name = "mobile-nixos-tested-plus";
    inherit constituents;
    meta = {
      description = ''
        Other targets that may be failing more often than `tested`.
        This contains more esoteric and less tested platforms.

        For a future release, `testedPlus` shoud also pass.
      '';
    };
  };
}
