{ config, lib, pkgs, ... }:

with lib;
with import ./initrd-order.nix;

let
  device_name = "TODO";
  cfg = config.mobile.boot.stage-1.ssh;
in
{
  options.mobile.boot.stage-1.ssh = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Enables ssh.
        CURRENT CONFIGURATION ALSO OPENS ACCESS TO ALL WITHOUT A PASSWORD NOR SSH KEY.
      '';
    };
  };

  config.mobile.boot.stage-1 = lib.mkIf cfg.enable {
    init = lib.mkOrder SERVICES_INIT ''
      #
      # Oh boy, that's insecure!
      #
      echo '/bin/sh' > /etc/shells
      echo 'root:x:0:0:root:/root:/bin/sh' > /etc/passwd
      echo 'passwd: files' > /etc/nsswitch.conf
      passwd -u root
      passwd -d root
      echo "From a mobile-nixos device ${device_name}" >> /etc/banner

      mkdir -p /etc/dropbear/

      # THIS IS HIGHLY INSECURE
      # This allows blank login passwords.
      dropbear -ERB -b /etc/banner
    '';
    extraUtils = with pkgs; [
      { package = dropbear; extraCommand = "cp -pv ${glibc.out}/lib/libnss_files.so.* $out/lib"; }
    ];
  };
}
