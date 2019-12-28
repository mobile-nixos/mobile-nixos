{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.mobile.boot.stage-1.loop-forever;
in
{
  options.mobile.boot.stage-1.loop-forever = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enables loop-forever.
        This will "freeze" the initrd, no switch root will happen.
        Enabling additional services (like `ssh`) will allow inspecting
        the stage-1 phase.
      '';
    };
  };

  config.mobile.boot.stage-1 = lib.mkIf cfg.enable {
    tasks = [
      (pkgs.writeText "loop-task.rb" ''
        class Tasks::LoopForever < SingletonTask
          def initialize()
            # Wedge the task between the target "root", and the
            # actual task we want to prevent running.
            add_dependency(:Target, :SwitchRoot)
            Tasks::SwitchRoot.instance.add_dependency(:Task, self)
          end

          def run()
            puts("\nLooping forever.\n")
            loop do
              sleep 3600
            end
          end
        end
      '')
    ];
  };
}
