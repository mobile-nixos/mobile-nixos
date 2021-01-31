# This hack unbinds and rebinds the currently problematic storage driver.
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
