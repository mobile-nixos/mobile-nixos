{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkOption
    types
  ;
  cfg = config.mobile.boot.stage-1.fbterm;
  fontsConf = pkgs.writeText "fonts.conf" ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <cachedir>/var/cache/fontconfig</cachedir>
      <dir>${pkgs.terminus_font}</dir>
    </fontconfig>
  '';
in
{
  options.mobile.boot.stage-1.fbterm = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enables fbterm.
      '';
    };
    fb = mkOption {
      type = types.str;
      default = "/dev/fb1";
      description = ''
        framebuffer to run fbterm on.
      '';
    };
    tty = mkOption {
      type = types.str;
      internal = true;
      default = "2";
      description = ''
        The tty to run on. This will be switched for you.

        This is used to side-step an issue where X11 will not start
        if fbterm is running on tty1 under some conditions.
      '';
    };
  };

  config.mobile.boot.stage-1 = lib.mkIf cfg.enable {
    tasks = [
      (pkgs.writeText "fbterm-task.rb" ''
        class Tasks::RunFBTerm < SingletonTask
          def initialize()
            add_dependency(:Target, :Graphics)
            add_dependency(:Mount, "/run")
            # Ensure this runs before SwitchRoot happens.
            # Otherwise this could never be ran!
            Tasks::SwitchRoot.instance.add_dependency(:Task, self)
          end

          def run()
            # Touching the logfile ensures that if the logging process fails,
            # fbterm will still run.
            FileUtils.mkdir_p("/run/log/")
            System.run("touch", "/run/log/stage-1.log")
            System.run("chvt", "${cfg.tty}")
            System.spawn(%q{
              export FB=${cfg.fb}
              exec fbterm -n terminus -s 32 -- tail -n 200 -f /run/log/stage-1.log < /dev/tty${cfg.tty}
            })
            # Ugh... this can coincide with being the last task to run before
            # SwitchRoot. When this happens, `fbterm` *somehow* fails to start
            # appropriately. I would much rather not have to wait for an
            # arbitrary amout of time and instead rely on signaling, but that
            # doesn't look trivial.
            # FIXME: investigate this issue.
            sleep(0.5)
          end

          def ux_priority()
            -1
          end
        end
      '')
    ];
    extraUtils = [
      { package = pkgs.fbterm; }
    ];
    contents = [
      { object = fontsConf; symlink = "/etc/fonts/fonts.conf"; }
    ];
  };
}
