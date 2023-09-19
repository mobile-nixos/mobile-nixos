{ config, lib, pkgs, ... }:

let
  inherit (lib)
    literalExpression
    mdDoc
    mkEnableOption
    mkIf
    mkOption
    types
  ;
  cfg = config.services.eg25-manager;
in
{
  options.services.eg25-manager = {
    enable = mkEnableOption (mdDoc "Quectel EG25 modem manager service");

    package = mkOption {
      type = types.package;
      default = pkgs.eg25-manager;
      defaultText = literalExpression "pkgs.eg25-manager";
      description = mdDoc ''
        The eg25-manager derivation to use.
      '';
    };
  };
  config = mkIf cfg.enable {
    systemd.packages = [ cfg.package ];
    services.udev.packages = [ cfg.package ];
    systemd.services.eg25-manager.wantedBy = [ "multi-user.target" ];
  };
}
