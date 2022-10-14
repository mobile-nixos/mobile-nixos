{ config, lib, ... }:

let
  inherit (lib)
    mkIf
  ;
in
{
  config = mkIf (config.mobile.boot.stage-1.enable && config.boot.plymouth.enable) {
    systemd.services.plymouth-start.wantedBy = [
      "sysinit.target"
    ];
  };
}
