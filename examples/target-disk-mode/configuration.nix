{ config, lib, pkgs, ... }:

let
  tdm-gui = "${pkgs.callPackage ./app {}}/libexec/app.mrb";
  internalStorageConfigured =
    config.mobile.boot.stage-1.bootConfig ? storage &&
    config.mobile.boot.stage-1.bootConfig.storage ? internal &&
    config.mobile.boot.stage-1.bootConfig.storage.internal != null
  ;
in
{
  mobile.boot.stage-1.tasks = [
    (# Slip an assertion here; nixos asserts only operate on `build.toplevel`.
    if !internalStorageConfigured
    then builtins.throw "mobile.boot.stage-1.bootConfig.storage.internal needs to be configured for ${config.mobile.device.name}."
    else pkgs.writeText "gui-task.rb" ''
      class Tasks::RunGui < SingletonTask
        def initialize()
          add_dependency(:Target, :Graphics)
          add_dependency(:Mount, "/run")
          add_dependency(:Files, "/dev/input")

          # Ensures networking and SSH works
          add_dependency(:Target, :Networking)
          add_dependency(:Task, Tasks::DropbearSSHD.instance)

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
          System.run(LOADER, "/applets/tdm-gui.mrb")
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

  mobile.boot.stage-1.contents = with pkgs; [
    {
      object = tdm-gui;
      symlink = "/applets/tdm-gui.mrb";
    }
  ];

  system.build = {
    app-simulator = pkgs.callPackage ./app/simulator.nix {};
    rootfs = null;
  };

  mobile.boot.stage-1.networking.enable = true;
  mobile.boot.stage-1.ssh.enable = true;
}
