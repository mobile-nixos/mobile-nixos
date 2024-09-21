{ config, lib, pkgs, ... }:

let
  inherit (lib) mkMerge mkIf mkOption types;
  cfg = config.mobile.boot.stage-1.shell;
in
{
  options.mobile.boot.stage-1.shell = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enables a shell before switching root.

        This shell (as currently configured) will not allow switching root.
      '';
    };
    console = mkOption {
      type = types.str;
      default = "console";
      description = ''
        Selects the /dev/___ device to use.

        Use `ttyS0` for serial, `tty1` for first VT or keep the default to `console`
        for the last defined `console=` kernel parameter.
      '';
    };

    shellOnFail = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enables a shell on failures.
      '';
    };
  };

  config.mobile.boot.stage-1 = mkMerge [
    (mkIf (cfg.enable || cfg.shellOnFail) {
      tasks = [
        (pkgs.writeText "system-shell.rb" ''
          module System
            def self.shell()
              # `cttyhack` ensures we get job control (^C, ^Z) going.
              cmd = %q{setsid /bin/sh -c 'setsid cttyhack sh; exec ash -mi' < /dev/${cfg.console} >/dev/${cfg.console} 2>/dev/${cfg.console}}
              $logger.debug(" $ #{cmd}")
              puts("\nExit this shell (CTRL+D) to resume booting.\n")
              system(cmd)
            end
          end
        '')
      ];
    })
    (mkIf cfg.enable {
      tasks = [
        (pkgs.writeText "run-shell-task.rb" ''
          class Tasks::RunShell < SingletonTask
            def initialize()
              # Wedge the task between the target "root", and the
              # actual task we want to prevent running.
              add_dependency(:Target, :SwitchRoot)
              Tasks::SwitchRoot.instance.add_dependency(:Task, self)
            end

            def run()
              System.shell()
            end
          end
        '')
      ];
    })
  ];
}
