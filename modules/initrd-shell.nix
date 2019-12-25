{ config, lib, pkgs, ... }:

with lib;

let
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
  };

  config.mobile.boot.stage-1 = lib.mkIf cfg.enable {
    tasks = [
      (pkgs.writeText "run-shell-task.rb" ''
        class Tasks::RunShell < SingletonTask
          def initialize()
            # Wedge the task between the target "root", and the
            # actual task we want to prevent running.
            add_dependency(:Target, :SwitchRoot)
            SwitchRoot.instance.add_dependency(:Task, self)
          end

          def run()
            cmd = %q{setsid /bin/sh -c /bin/sh < /dev/${cfg.console} >/dev/${cfg.console} 2>/dev/${cfg.console}}
            $logger.debug(" $ #{cmd}")
            puts("\nExit this shell (CTRL+D) to resume booting.\n")
            system(cmd)
          end
        end
      '')
    ];
  };
}
