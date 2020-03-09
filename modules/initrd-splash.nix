{ config, lib, pkgs, ... }:

{
  # This happens in stage-2. This is why we're not using `addSplash`.
  # This is the earliest in stage-2 we can show, for vt-less devices, that
  # stage-2 is really happening.
  config.boot.postBootCommands = ''
    ${pkgs.ply-image}/bin/ply-image --clear=0x000000 ${../artwork/splash.stage-2.png} > /dev/null 2>&1
  '';
}
