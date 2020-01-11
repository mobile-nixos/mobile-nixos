{ config, lib, pkgs, ... }:

let
  inherit (lib) mkOption types;
  cfg = config.mobile.boot.stage-1.bootlogd;
in
{
  options.mobile.boot.stage-1.bootlogd = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Enables bootlogd logging multiplexer.
      '';
    };
  };

  config.mobile.boot.stage-1 = lib.mkIf cfg.enable {
    tasks = [
      # FIXME: This happens "too late".
      # The logging starts when bootlogd is started (obviously).
      # We need to figure out a way to make it "catch-up" with the existing
      # output.
      (pkgs.writeText "bootlogd-task.rb" ''
        class Tasks::RunBootlogd < SingletonTask
          def initialize()
            add_dependency(:Target, :Environment)
            add_dependency(:Mount, "/proc")
            add_dependency(:Mount, "/dev")
            add_dependency(:Mount, "/dev/pts")
            Targets[:Devices].add_dependency(:Task, self)
          end

          def run()
            System.spawn("bootlogd -c")
          end

          def ux_priority()
            -100
          end
        end
      '')
    ];
    extraUtils = with pkgs; [
      { package = bootlogd; }
    ];
  };
}
