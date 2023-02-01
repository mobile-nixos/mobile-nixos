/**
 * Evaluates the configuration for a disk image build.
 */
{ pkgs
, modules ? []
, config ? {}
}:
let config' = config; in
rec {
  module = { imports = import ./module-list.nix; };
  config = (pkgs.lib.evalModules {
    modules = [
      { _module.args.pkgs = pkgs; }
      module
      config'
    ] ++ modules;
  }).config;
}
