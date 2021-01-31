{ config, lib, pkgs, ... }:

{
  mobile.device.name = "asus-dumo";
  mobile.device.identity = {
    name = "Chromebook Tablet CT100PA";
    manufacturer = "Asus";
  };

  mobile.hardware = {
    soc = "rockchip-op1";
    ram = 1024 * 4;
    screen = {
      width = 1536; height = 2048;
    };
  };

  mobile.boot.stage-1 = {
    kernel.package = pkgs.callPackage ./kernel {};
  };

  mobile.system.depthcharge.kpart = {
    dtbs = "${config.mobile.boot.stage-1.kernel.package}/dtbs/rockchip";
  };

  # Serial console on ttyS2, using a suzyqable or equivalent.
  boot.kernelParams = [
    "console=ttyS2,115200n8"
    "earlyprintk=ttyS2,115200n8"
    "vt.global_cursor_default=0"
  ];

  mobile.system.type = "depthcharge";

  mobile.device.firmware = pkgs.callPackage ./firmware {};
  mobile.boot.stage-1.firmware = [
    config.mobile.device.firmware
  ];

  # The controller is hidden from the OS unless started using the "android"
  # launch option in the weird UEFI GUI chooser.
  mobile.usb.mode = "gadgetfs";

  # Commonly re-used values, Nexus 4 (debug)
  # (These identifiers have well-known default udev rules.)
  mobile.usb.idVendor = "18d1";
  mobile.usb.idProduct = "d002";

  # Mainline gadgetfs functions
  mobile.usb.gadgetfs.functions = {
    rndis = "rndis.usb0";
    mass_storage = "mass_storage.0";
    adb = "ffs.adb";
  };

  mobile.boot.stage-1.bootConfig = {
    # Used by target-disk-mode to share the internal drive
    storage.internal = "/dev/disk/by-path/platform-fe330000.sdhci";
  };

  mobile.boot.stage-1.tasks = [
    # This hack unbinds and rebinds the currently problematic storage driver.
    # TODO: move into a generic "gru family" thing.
    (pkgs.writeText "fixup-sdhci-arasan.rb" ''
      class Tasks::FixupSDHCIArasan < SingletonTask
        MAX = 60;
        NAME = "fe330000.sdhci"
        DRIVER = "/sys/bus/platform/drivers/sdhci-arasan"
        GLOB = "#{DRIVER}/#{NAME}/mmc_host/mmc*/mmc*/block"

        def initialize()
          add_dependency(:Mount, "/sys")
          add_dependency(:Files, DRIVER)
          #add_dependency(:Target, :Environment)
        end

        def run()
          tries = 0

          $stdout.print " -> Waiting for #{NAME}"
          $stdout.flush
          until Dir.glob(GLOB).length > 0 do
            $stdout.print "."
            $stdout.flush
            tries += 1
            begin
              System.write(File.join(DRIVER, "unbind"), NAME)
            rescue => e
              $logger.fatal(e.inspect)
            end
            begin
              System.write(File.join(DRIVER, "bind"), NAME)
            rescue => e
              $logger.fatal(e.inspect)
            end

            sleep(1)
            raise "Couldn't get #{NAME} up in #{tries} tries." if tries > MAX
          end
          $stdout.puts "!\n"

          log("Took #{tries} tries for #{NAME} to appear...")
        end
      end
    '')
  ];
}
