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

    begin
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
    end

    @pid = nil
  end

  # Use `quit` rather than kill!
  def kill()
    System.run("kill", "-9", @pid.to_s) if @pid
  end
end
