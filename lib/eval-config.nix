# This file is based on <nixpkgs/nixos/lib/eval-config.nix>.

# From a device configuration, build an initrd.

{ # !!! system can be set modularly, would be nice to remove
  system ? builtins.currentSystem
, # !!! is this argument needed any more? The pkgs argument can
  # be set modularly anyway.
  pkgs ? null
, # !!! what do we gain by making this configurable?
  baseModules ? import ../modules/module-list.nix
, # !!! See comment about args in lib/modules.nix
  extraArgs ? {}
, # !!! See comment about args in lib/modules.nix
  specialArgs ? {}
, modules
, # !!! See comment about check in lib/modules.nix
  check ? true
, prefix ? []
, lib ? import <nixpkgs/lib>
}:

let extraArgs_ = extraArgs; pkgs_ = pkgs;
in

let
  pkgsModule = rec {
    _file = ./eval-config.nix;
    key = _file;
    config = {
      nixpkgs.localSystem = lib.mkDefault { inherit system; };
      _module.args.pkgs = lib.mkIf (pkgs_ != null) (lib.mkForce pkgs_);
    };
  };

in rec {

  # Merge the option definitions in all modules, forming the full
  # system configuration.
  inherit (lib.evalModules {
    inherit prefix check;
    modules = modules ++ baseModules ++ [ pkgsModule ];
    args = extraArgs;
    specialArgs = { modulesPath = ../modules; } // specialArgs;
  }) config options;

  # These are the extra arguments passed to every module.  In
  # particular, Nixpkgs is passed through the "pkgs" argument.
  extraArgs = extraArgs_ // {
    inherit modules baseModules;
  };

  inherit (config._module.args) pkgs;
}
