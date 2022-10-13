#
# Workarounds for using zram with mayby non-module kernels.
#
# (Not upstreamed to Nixpkgs since it assumes breakage in NixOS's assumptions.)
#
{ config, lib, pkgs, ... }:

let
  modprobe = "${pkgs.kmod}/bin/modprobe";
in
{
  config = lib.mkIf config.zramSwap.enable {
    systemd.services.zram-reloader.serviceConfig = {
      ExecStartPre = lib.mkForce (pkgs.writeShellScript "zram-reloader-start-pre" ''
         if ${pkgs.gzip}/bin/zcat /proc/config.gz | ${pkgs.gnugrep}/bin/grep -q ^CONFIG_ZRAM=m; then
           ${modprobe} -r zram
         fi
      '');
      ExecStart = lib.mkForce (pkgs.writeShellScript "zram-reloader-start" ''
         if ${pkgs.gzip}/bin/zcat /proc/config.gz | ${pkgs.gnugrep}/bin/grep -q ^CONFIG_ZRAM=m; then
           ${modprobe} zram
         fi
      '');
      ExecStop = lib.mkForce (pkgs.writeShellScript "zram-reloader-stop" ''
         if ${pkgs.gzip}/bin/zcat /proc/config.gz | ${pkgs.gnugrep}/bin/grep -q ^CONFIG_ZRAM=m; then
           ${modprobe} -r zram
         fi
      '');
    };
  };
}
