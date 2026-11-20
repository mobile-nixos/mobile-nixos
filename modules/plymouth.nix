{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkIf
    mkMerge
  ;
in
{
  config = mkMerge [
    (mkIf (config.mobile.boot.stage-1.enable && config.boot.plymouth.enable) {
      systemd.services.plymouth-start.wantedBy = [
        "sysinit.target"
      ];
    })
    (mkIf config.services.xserver.desktopManager.phosh.enable {
      # plymouth leaves the console tty (tty2 under silentBoot) as the
      # foreground VT; switch back to tty1 so logind can activate phosh.
      systemd.services.phosh.serviceConfig.ExecStartPre = [
        "+${pkgs.kbd}/bin/chvt 1"
      ];
    })
  ];
}
