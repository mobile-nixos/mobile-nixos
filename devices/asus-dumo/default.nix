{ config, lib, pkgs, ... }:

{
  mobile.device.name = "asus-dumo";
  mobile.device.identity = {
    name = "Chromebook Tablet CT100PA";
    manufacturer = "Asus";
  };

  mobile.device.info = rec {
    # TODO : move kernel outside of the basic device details
    kernel = pkgs.callPackage ./kernel {};
    # This could be further pared down to only the required dtb files.
    dtbs = "${kernel}/dtbs/rockchip";
  };
  mobile.hardware = {
    soc = "rockchip-op1";
    ram = 1024 * 4;
    screen = {
      width = 1536; height = 2048;
    };
  };

  # Serial console on ttyS2, using a suzyqable or equivalent.
  boot.kernelParams = [
    "console=ttyS2,115200n8"
    "earlyprintk=ttyS2,115200n8"
    "loglevel=8"
    "vt.global_cursor_default=0"
  ];

  mobile.system.type = "depthcharge";

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
