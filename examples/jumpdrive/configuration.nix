{ config, lib, pkgs, ... }:

let
  jumpdrive-gui = pkgs.runCommand "jumpdrive-gui.mrb" {} ''
    ${pkgs.buildPackages.mruby}/bin/mrbc -o $out \
      ${../../boot/gui/lib}/*.rb \
      ${./gui}/lib/*.rb \
      ${./gui}/main.rb
  '';
in
{
  mobile.boot.stage-1.tasks = [
    (pkgs.writeText "demo-task.rb" ''
      class Tasks::RunDemo < SingletonTask
        def initialize()
          add_dependency(:Target, :Graphics)
          add_dependency(:Mount, "/run")
          add_dependency(:Files, "/dev/input")
          # Ensure this runs before SwitchRoot happens.
          # Otherwise this could never be ran!
          Tasks::SwitchRoot.instance.add_dependency(:Task, self)
          add_dependency(:Task, Tasks::SetupGadgetMode.instance)

          # Ensure shell runs once before.
          if Tasks.const_defined?(:RunShell)
            add_dependency(:Task, Tasks::RunShell.instance)
            Tasks::RunShell.instance.add_dependency(
              :Task,
              Tasks::SetupGadgetMode.instance
            )
          end
        end

        def run()
          # FIXME: weirdness with /dev/inputs in QEMU.
          sleep(1)
          System.run($PROGRAM_NAME, "/applets/jumpdrive-gui.mrb")
          # Exit the whole program at that point, if for any reason there's a
          # failure. This shouldn't happen anyway.
          exit(1)
        end

        def ux_priority()
          -10000
        end
      end
    '')
  ];

  # There is no mounting here.
  fileSystems = lib.mkForce {};

  mobile.boot.stage-1.usb = {
    enable = true;
    features = [ "mass_storage" ];
  };

  mobile.boot.stage-1.bootConfig = {
    # TODO: figure out a better way to provide this information.
    storage.internal = {
      pine64-pinephone = "/dev/disk/by-path/platform-1c11000.mmc";
    }.${config.mobile.device.name};
  };
  mobile.boot.stage-1.contents = with pkgs; [
    {
      object = jumpdrive-gui;
      symlink = "/applets/jumpdrive-gui.mrb";
    }
  ];

  system.build.rootfs = null;

  mobile.boot.stage-1.networking.enable = true;
  mobile.boot.stage-1.ssh.enable = true;
}
