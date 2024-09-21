{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkOption
    types
  ;
  device_name = config.mobile.device.name;
  cfg = config.mobile.boot.stage-1.ssh;
  banner = pkgs.writeText "${device_name}-banner" ''
    From a mobile-nixos device ${device_name}
  '';
in
{
  options.mobile.boot.stage-1.ssh = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enables ssh during stage-1.

        **CURRENT CONFIGURATION ALSO OPENS ACCESS TO ALL WITHOUT A PASSWORD NOR SSH KEY.**
      '';
    };
  };

  config.mobile.boot.stage-1 = lib.mkIf cfg.enable {
    tasks = [
      # Oh boy, that's insecure! (As documented.)
      (pkgs.writeText "insecure-root-password-task.rb" ''
        class Tasks::InsecureRootPassword < SingletonTask
          def initialize()
            add_dependency(:Target, :Environment)
          end
          
          def run()
            # Puts a blank password for the root user.
            System.run("passwd", "-d", "root")
          end
        end
      '')
      (pkgs.writeText "dropbear-sshd-task.rb" ''
        class Tasks::DropbearSSHD < SingletonTask
          def initialize()
            add_dependency(:Target, :Networking)
            Targets[:SwitchRoot].add_dependency(:Task, self)
          end
          
          def run()
            FileUtils.mkdir_p("/etc/dropbear")
            # THIS IS HIGHLY INSECURE
            # This allows blank login passwords.
            System.spawn("dropbear", "-ERB", "-b", "/etc/banner")
          end
        end
      '')
    ];
    contents = [
      { object = banner; symlink = "/etc/banner"; }
    ];
    extraUtils = [
      { package = pkgs.dropbear; extraCommand = "cp -fpv ${pkgs.glibc.out}/lib/libnss_files.so.* $out/lib"; }
    ];
  };
}
