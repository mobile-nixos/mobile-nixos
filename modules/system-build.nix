{ config, lib, pkgs, ... }:

with lib;

{
  options.system.build = mkOption {
    internal = true;
    description = ''
      Where the result will be put into.
      This ends up building `all`.
    '';
  };
}
