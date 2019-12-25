{ config, lib, pkgs, ... }:

with lib;

let
  device_name = config.mobile.device.name;
  cfg = config.mobile.boot.stage-1.ssh;
in
{
  options.mobile.boot.stage-1.ssh = {
    enable = mkOption {
      type = types.bool;
      default = false;
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
      passwd -u root
      passwd -d root
      echo "From a mobile-nixos device ${device_name}" >> /etc/banner

      mkdir -p /etc/dropbear/

      # THIS IS HIGHLY INSECURE
      # This allows blank login passwords.
      dropbear -ERB -b /etc/banner
    '';
    extraUtils = with pkgs; [
      { package = dropbear; extraCommand = "cp -fpv ${glibc.out}/lib/libnss_files.so.* $out/lib"; }
    ];
  };
}
