# This is intended to be used to produce a bootable `boot.img` with adbd, and
# dropbear enabled. You would, in turn, use it to "flash" a dumb system.img file
# to a partition, like userdata.
#
# *CAUTION* : there is no protection against flashing over the wrong partition.
# Read about the usual pitfalls in the Android section of the documentation.
{ config, lib, pkgs, ... }:

let
  device_info = config.mobile.device.info;
in
{
  # Ensures we don't quit stage-1
  mobile.boot.stage-1.shell.enable = true;
  # Only enable `adb` if we know how to.
  # FIXME: relies on implementation details. Poor separation of concerns.
  mobile.adbd.enable = (config.mobile.system.type == "android") &&
    (config.mobile.usb.mode != "gadgetfs" || device_info.gadgetfs.functions ? ffs)
  ;

  # Enables networking and ssh in stage-1 !
  mobile.boot.stage-1.networking.enable = true;
  mobile.boot.stage-1.ssh.enable = true;
  mobile.boot.stage-1.fbterm.enable = true;
  mobile.boot.stage-1.tasks = [
    (pkgs.writeText "adjust-brightness-task.rb" ''
      class Tasks::AdjustBrightness < SingletonTask
        def initialize()
          add_dependency(:Target, :Environment)
          add_dependency(:Target, :Graphics)
        end

        def run()
          ["lcd-backlight", "wled"].each do |file|
            # This can fail to write, ignore...
            begin
              max = File.read("/sys/class/leds/#{file}/max_brightness").to_i
              System.write("/sys/class/leds/#{file}/brightness", (max * 0.1).to_i)
            rescue
            end
          end
        end
      end
    '')
  ];
}
