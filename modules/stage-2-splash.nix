{ config, lib, pkgs, ... }:

{
  # This is the earliest in stage-2 we can show, for vt-less devices, that
  # stage-2 is really happening.
  config.boot.postBootCommands = ''
    # Reset the VT console.
    # The Mobile NixOS stage-1 can be rude.
    for d in /sys/class/vtconsole/vtcon*; do
      if ${pkgs.busybox}/bin/grep 'frame buffer' "$d/name"; then
        echo 1 > "$d/bind"
      fi
    done
    # Though directly rudely show the stage-2 splash.
    ${pkgs.ply-image}/bin/ply-image --clear=0x000000 ${../artwork/splash.stage-2.png} > /dev/null 2>&1
  '';
}
