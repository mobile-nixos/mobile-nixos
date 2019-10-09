{ config, lib, pkgs, ... }:

with lib;
with import ./initrd-order.nix;

let
  cfg = config.mobile.boot.stage-1.devices-init;
in
{
  options.mobile.boot.stage-1.devices-init = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Enables devices-init.
        This probably shouldn't be disabled, unless you implement
        a different one.
      '';
    };
  };

  config.mobile.boot.stage-1 = lib.mkIf cfg.enable {
    init = lib.mkOrder DEVICE_INIT ''
      mkdir -p /proc /sys /dev
      mount -t devtmpfs devtmpfs /dev
      mount -t proc proc /proc
      mount -t sysfs sysfs /sys

      mkdir -p /etc/udev /tmp /run /lib /mnt /var/log

      # Some tools, notably extfs tools, will bark angrily
      # when they cannot determine if the device is mounted.
      ln -s /proc/mounts /etc/mtab

      mkdir -p /dev/pts
      mount -t devpts devpts /dev/pts

      touch /var/log/lastlog

      # Basic stuff necessary for a shell.
      echo '/bin/sh' > /etc/shells
      echo 'root:*:0:0:root:/root:/bin/sh' > /etc/passwd
      echo 'passwd: files' > /etc/nsswitch.conf
    '';
  };
}
