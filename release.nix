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

# Takes a lot of RAM to evaluate `tested` and `testedPlus`.
, fullRelease ? false

# The current system, for pure evals it must be provided.
, system ? null

# The Nixpkgs this release is evaluated with.
# By default relies on the pinned Nixpkgs.
, pkgs ? null

# This parameter allows the tooling to ask for the “internal” representation
# of the release jobset CI information. In turn, this can be used to extract
# a bit more information, which does not make sense for nix-build.
, evalForCI ? false

# When dryRun is true, the evaluation does not attempt to produce
# derivations, it only makes the structure of the attrs.
# This allows verifying that the evaluation for the attrset structure
# of the release file is cheap, and also makes it possible to introspect
# the release for attribute-per-attribute instantiating.
, dryRun ? false
}@args':

# Additional arguments handling.
let
  mobileReleaseTools = (import ./lib/release-tools.nix { inherit pkgs; });

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

  devices =
    if args' ? devices && args'.devices != null
    then args'.devices
    else mobileReleaseTools.all-devices
  ;

  inherit (pkgs.lib)
    attrByPath
    filterAttrs
    filterAttrsRecursive
    genAttrs
    getAttrFromPath
    isDerivation
    isList
    mapAttrs
    mapAttrsRecursive
    optionalAttrs
    unique
  ;

  toAttrPath = pkgs.lib.splitString ".";

  inherit (mobileReleaseTools)
    readOverlayAttributeNames
    recurseIntoPackageSet
  ;

  inherit (mobileReleaseTools.withPkgs pkgs)
    evalFor
    evalWithConfiguration
    specialConfig
  ;

  # Systems we should eval for, per host system.
  # Non-native will be assumed cross.
  fromLocalSystemToCrossTargets =
    {
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
    }
  ;

  # For a given system, return systems on which it could be compiled from.
  # In other words, given a system in this attrset, list all systems it should be evaluated on.
  fromTargetToSystems =
    builtins.listToAttrs
    (
      builtins.map
      (
        system:

        {
          name = system;
          value =
            builtins.filter
            (name: (builtins.elem system fromLocalSystemToCrossTargets.${name}))
            (builtins.attrNames fromLocalSystemToCrossTargets)
          ;
        }
      )
      (unique (builtins.concatLists (builtins.attrValues fromLocalSystemToCrossTargets)))
    )
  ;

  # An attrset of `$device = $system;` entries.
  # This is used to build the cross/non-cross matrices
  # Cost for evaluating this
  deviceSystems =
    genAttrs devices (
      device: (evalWithConfiguration {} device).config.mobile.system.system
    )
  ;

  releaseConfigs = {
    "unconfigured" = {};
    "hello" = {
      configuration = {
        imports = [
          ./examples/hello/configuration.nix
        ];
      };
    };
    "installer" = {
      configuration = {
        imports = [
          ./examples/installer/configuration.nix
        ];
      };
      # Not a useful build output
      evalForCross = false;
    };
    "phosh" = {
      configuration = {
        imports = [
          ./examples/phosh/configuration.nix
        ];
      };
      # Don't even try
      evalForCross = false;
    };
    "plasma-mobile" = {
      configuration = {
        imports = [
          ./examples/plasma-mobile/configuration.nix
        ];
      };
      # Don't even try
      evalForCross = false;
    };
  };

  evalAllConfigs =
    { device, system, dryRun, releaseConfigs }:
    genAttrs (builtins.attrNames releaseConfigs)
    (
      name:
      with (
        {
          inherit name;
          configuration = {};
        } // releaseConfigs.${name}
      );
      let
        eval = evalWithConfiguration configuration device;
        dryRunValue = valueName: "<unrealized eval for ${device} ${valueName}>";
        attrs = [
          "default" "initrd" "toplevel"
        ];
      in
      if dryRun
      then {
        kernel = dryRunValue "kernel";
      } // (genAttrs attrs dryRunValue)
      else {
        kernel = eval.config.mobile.boot.stage-1.kernel.package;
      } // (genAttrs attrs (name: eval.config.mobile.outputs.${name}))
    )
  ;

  evalDeviceForSystem =
    { system, device, dryRun }:

    let
      crossReleaseConfigs = filterAttrs (name: value: value.evalForCross or true) releaseConfigs;
      crossTargets =
        builtins.filter
        (el: el != system && builtins.elem el systems)
        (fromTargetToSystems.${system})
      ;
    in
    {
      cross =
        genAttrs
        crossTargets
        (
        localSystem:
        evalAllConfigs { inherit device dryRun; system = localSystem; releaseConfigs = crossReleaseConfigs; }
        )
      ;
    } // (optionalAttrs (builtins.elem system systems) {
      native = evalAllConfigs { inherit device system dryRun releaseConfigs; };
    })
  ;

  overlayJobs =
    let
      # A cheap evaluation of (most) of the shape of our overlay.
      # It will be missing `recurseForDerivations` attrsets from `callPackage` invocations.
      # Though that's not an issue, since those will be found when evaluating.
      overlayAttrs =
        readOverlayAttributeNames
        (
          bogusPkgs:
          # Workarounds for inter-dependencies...
          {
            image-builder = false;
            mobile-nixos = bogusPkgs // {
              stage-1 = bogusPkgs // {
                boot-recovery-menu = bogusPkgs // {
                  simulator = bogusPkgs.__tarpit;
                };
                boot-splash = bogusPkgs // {
                  simulator = bogusPkgs.__tarpit;
                };
              };
            };
          }
        )
        (import ./overlay/overlay.nix)
      ;

      # Extract the overlayAttrs shape from the "full" `pkgs` from a the given evaluation.
      evalOverlay =
        { eval }:
        mapAttrsRecursive
        (path: value:
        let
          drv = getAttrFromPath value eval.pkgs;
        in
          if !(isList value) then value else
          if (isDerivation drv)
          then (
            if dryRun
            then "<unrealized eval for overlay entry ${builtins.concatStringsSep "." value}>"
            else drv
          )
          else null
        )
        (
          filterAttrsRecursive
          (path: value: value != null)
          (recurseIntoPackageSet { packageset = overlayAttrs; inherit eval; })
        )
      ;
    in
    (
      genAttrs (systems) (
        system:
        let
          evals =
            builtins.listToAttrs (
              builtins.map (
                name:
                rec {
                  inherit name;
                  value = evalFor (specialConfig {
                    inherit name system;
                    buildingForSystem = name;
                  });
                }
              ) fromLocalSystemToCrossTargets.${system})
          ;
          crossSystems =
            builtins.filter
            (el: el != system)
            fromLocalSystemToCrossTargets.${system}
          ;
        in
        ({
        }) // (optionalAttrs (crossSystems != []) {
          cross = genAttrs crossSystems (
            crossSystem:
            (evalOverlay { eval = evals.${crossSystem}; })
          );
        }) // (optionalAttrs (builtins.elem system systems) {
          native =
            (evalOverlay { eval = evals.${system}; })
          ;
        })
      )
    )
  ;

  #
  # This attrset contains buckets of attr paths for `jobs`.
  #
  # It is used by the GitHub workflow to build matrices.
  #
  # Dependencies can be described using the list on the attrpaths.
  # With proper cache configuration, it allows re-using outputs.
  # NOTE: GibHub actions can't use the dependencies at this point in time.
  #
  # NOTE: This must produce a maximum of 256 outputs. (Per-bucket?)
  #        - https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/running-variations-of-jobs-in-a-workflow#using-a-matrix-strategy
  buildInCI = {
    #
    # Critical packages
    #
    overlay = {
      "overlay.aarch64-linux.native.mobile-nixos.boot-control" = [ ];
      "overlay.aarch64-linux.native.mobile-nixos.cross-canary-test-static" = [ ];
      "overlay.aarch64-linux.native.mobile-nixos.stage-1.boot-error" = [ "overlay.aarch64-linux.native.mobile-nixos.stage-1.script-loader" ];
      "overlay.aarch64-linux.native.mobile-nixos.stage-1.boot-splash" = [ "overlay.aarch64-linux.native.mobile-nixos.stage-1.script-loader" ];
      "overlay.aarch64-linux.native.mobile-nixos.stage-1.boot-recovery-menu" = [ "overlay.aarch64-linux.native.mobile-nixos.stage-1.script-loader" ];
      "overlay.aarch64-linux.native.mobile-nixos.stage-1.script-loader" = [ ];
      "overlay.x86_64-linux.cross.aarch64-linux.mobile-nixos.cross-canary-test" = [ ];
      "overlay.x86_64-linux.cross.aarch64-linux.mobile-nixos.cross-canary-test-static" = [ ];
      "overlay.x86_64-linux.cross.aarch64-linux.mobile-nixos.stage-1.boot-error" = [ "overlay.x86_64-linux.cross.aarch64-linux.mobile-nixos.stage-1.script-loader" ];
      "overlay.x86_64-linux.cross.aarch64-linux.mobile-nixos.stage-1.boot-splash" = [ "overlay.x86_64-linux.cross.aarch64-linux.mobile-nixos.stage-1.script-loader" ];
      "overlay.x86_64-linux.cross.aarch64-linux.mobile-nixos.stage-1.boot-recovery-menu" = [ "overlay.x86_64-linux.cross.aarch64-linux.mobile-nixos.stage-1.script-loader" ];
      "overlay.x86_64-linux.cross.aarch64-linux.mobile-nixos.stage-1.script-loader" = [ ];
    };

    #
    # Kernels
    #
    kernels =
      builtins.listToAttrs
      (
        builtins.concatLists (builtins.map (
        device:
        [
          { name = "devices.${device}.cross.x86_64-linux.unconfigured.kernel"; value = [ ]; }
          { name = "devices.${device}.native.unconfigured.kernel"; value = [ ]; }
        ]
        ) mobileReleaseTools.all-devices)
      )
    ;

    #
    # Image Builds
    #
    images =
      (mapAttrs (
        name: value:
        let
          # Pick .unconfigured.kernel as a dependency.
          kernel = 
            builtins.replaceStrings
            (builtins.match ".*(\\.[^.]+)(\\.[^.]+)" name)
            [ ".unconfigured" ".kernel" ]
            name
          ;
        in
        [
          kernel
        ]
      ) {
        #
        # `hello`, native and cross
        #
        # NOTE: One device per "family" is sufficient.
        #       These are not intended for distribution, but for CI.
        #

        # A64
        "devices.pine64-pinephone.cross.x86_64-linux.hello.default" = [ ];
        "devices.pine64-pinephone.native.hello.default" = [ ];
        # RK3399
        "devices.pine64-pinephonepro.cross.x86_64-linux.hello.default" = [ ];
        "devices.pine64-pinephonepro.native.hello.default" = [ ];
        # SDM845 android
        # (Images not enabled for now: requires non-free firmware in the build.)
        #"devices.oneplus-enchilada.native.hello.default" = [ ];
        #"devices.oneplus-enchilada.cross.x86_64-linux.hello.default" = [ ];
        # SC7180 depthcharge
        "devices.lenovo-wormdingler.native.hello.default" = [ ];
        "devices.lenovo-wormdingler.cross.x86_64-linux.hello.default" = [ ];
        # MT8183 depthcharge
        "devices.lenovo-krane.native.hello.default" = [ ];
        "devices.lenovo-krane.cross.x86_64-linux.hello.default" = [ ];

        #
        # Installers
        #

        # U-Boot systems
        "devices.pine64-pinephone.native.installer.default" = [ ];
        "devices.pine64-pinephonepro.native.installer.default" = [ ];
        "devices.pine64-pinetab.native.installer.default" = [ ];

        # Depthcharge systems
        "devices.acer-juniper.native.installer.default" = [ ];
        "devices.acer-lazor.native.installer.default" = [ ];
        "devices.lenovo-krane.native.installer.default" = [ ];
        "devices.lenovo-wormdingler.native.installer.default" = [ ];
      })
    ;
  };

  filteredBuildInCI =
    mapAttrs
    (jobsList: jobs:
      filterAttrs
      (jobName: deps: (attrByPath (toAttrPath jobName) false CI.jobs) != false)
      jobs
    )
    buildInCI
  ;

  # This attribute set contains the jobs (the only thing exposed by default)
  # and additional metadata / configuration that the CI infrastructure can use.
  CI = {
    _data = {
      inherit
        fromLocalSystemToCrossTargets
        fromTargetToSystems
        deviceSystems
        buildInCI
        filteredBuildInCI
      ;
    };


    jobs = {
      overlay = overlayJobs;
      devices =
        genAttrs devices (
          device:
          let
            system = (evalWithConfiguration {} device).config.mobile.system.system;
          in
          evalDeviceForSystem {
            inherit dryRun;
            inherit system device;
          }
        )
      ;
    };
  };
in

if evalForCI
then CI
else CI.jobs
