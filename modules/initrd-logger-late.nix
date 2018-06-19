{ config, lib, pkgs, ... }:

with lib;
with import ./initrd-order.nix;

let
  cfg = config.mobile.boot.stage-1.redirect-log;

  # Used in the script
  logger_run = "/run/initrd";
  pidfile = "${logger_run}/init.log.pid";
in
{
  config.mobile.boot.stage-1 = {
    # FIXME : this may not cleanup nicely.
    # This implementation is naive and simple.
    init = lib.mkOrder AFTER_SWITCH_ROOT_INIT ''
      _stop_logger() {
        local i=0 pid
        # re-attach to /dev/console
        exec 0<>/dev/console 1<>/dev/console 2<>/dev/console
        # Kill the process
        kill $(cat ${pidfile})
      }
    '';
  };
}
