# Adds a minimal set of files required for logging-in.
class Tasks::Splash < SingletonTask
  def initialize()
    add_dependency(:Target, :Graphics)
    add_dependency(:Task, Tasks::ProgressSocket.instance)
  end

  def run()
    args = []
    if LOG_LEVEL ==  Logger::DEBUG
      args << "--verbose"
    end

    if System.cmdline().grep("mobile-nixos.kexec=yes").any?
      args << "--skip-fadein"
    end

    wait_for_input_devices

    begin
      $logger.info "Starting splash..."
      @pid = System.spawn(LOADER, "/applets/boot-splash.mrb", *args)
    # Don't fail the boot if the splash fails
    rescue System::CommandError
    end
  end

  def ux_priority()
    -100
  end

  # Implementation details-y; ask for the splash applet to be exited.
  def quit(reason, sticky: nil)
    return if @pid.nil?

    count = 0
    # Ensures the progress is shown
    Progress.update({progress: 100, label: reason})

    # Command it to quit
    Progress.update({command: {name: "quit"}, sticky: sticky})

    # Ensures that if for any reason the splash didn't start in time for the
    # socket to listen to this message, that we'll be quitting it.
    loop do
      # Repeatedly send the current state (which has the quit command).
      Progress.send_state()
      # If it has quit, break out!
      break if Process.wait(@pid, Process::WNOHANG)

      # Leave some breathing room to the CPU!
      sleep(0.1)
      count += 1
      if count > 60 # 10 seconds~ish
        $logger.fatal("Splash applet would not quit by itself...")
        kill
        break
      end
    end

    @pid = nil
  end

  # Use `quit` rather than kill!
  def kill()
    System.run("kill", "-9", @pid.to_s) if @pid
  end

  # Return an appropriate enough count for devices and busses.
  # This is used to approximate if all devices on e.g. USB have
  # finished showing up.
  def count_device_nodes()
    [
      "/dev/input/event*",
      "/sys/bus/usb/devices/*",
    ]
      .map { |pattern| Dir.glob(pattern).length }
      .reduce(&:+)
  end

  def wait_for_input_devices()
    unless Configuration["quirks"] && Configuration["quirks"]["wait_for_devices_delay"]
      return
    end

    # Minimum amount of time spent waiting for devices, in seconds.
    wait_for_devices_delay = Configuration["quirks"]["wait_for_devices_delay"]

    # Number of times this is looking at the state every second.
    # This is the "precision" at which it works, e.g. wait_for_devices_delay + (1.0/looks_per_second)
    # is the approximative minimum amount of time this will wait for.
    # > If we looked once per second, it would be 2+1 = 3 seconds
    # > If we look five times per second, it will be 2+0.2 = 2.2 seconds
    # > Not a lot saved, but about 25% faster.
    looks_per_second = 5

    # We're counting down from this amount, and will need to reset.
    stable_counts_max = wait_for_devices_delay * looks_per_second

    puts "\n"
    $logger.info "Waiting for input devices to settle..."
    puts "\n"

    stable_counts = stable_counts_max
    last_count = 0

    # We'll be looping until the device node count is stable.
    until stable_counts == 0
      # Wait a bit
      sleep(1.0/looks_per_second)

      # Anything changed?
      if last_count != count_device_nodes() then
        # Reset the counter!
        print "!"
        last_count = count_device_nodes()
        stable_counts = stable_counts_max
      else
        # Count down one
        stable_counts -= 1
        print "."
      end
    end
    print "\n"
  end
end
