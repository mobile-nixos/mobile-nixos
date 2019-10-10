{ config, lib, pkgs, ... }:

let
  inherit (lib) mkOption types;
  cfg = config.mobile.hardware;
in
{
  # All family files are always loaded.
  # They, themselves, need to guard themselves using the value of `family`.
  # That is, until a method of loading an imports file based on the value of an
  # option is figured out.
  imports = [
    ./families/chromebook-gru.nix
  ];

  options.mobile.hardware = {
    family = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Give the hardware family name for the device.
      '';
    };
  };
}
