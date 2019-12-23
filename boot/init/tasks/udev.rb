# Runs udev daemon
class Tasks::UDev < SingletonTask
  def initialize()
    add_dependency(:SingletonTask, :Environment)
    add_dependency(:Files, "/dev/null")
    add_dependency(:Files, "/proc/cmdline")
    add_dependency(:Files, "/run")
  end

  def udevadm(*args)
    System.run("udevadm", *args)
  end

  def run()
    udevd
    udevadm("trigger", "--action=add")
    udevadm("settle")
  end

  def udevd()
    *args = []
    args << "--debug" if debug?
    System.run("systemd-udevd", "--daemon", *args)
  end

  # TODO: Allow configuring its debug state
  def debug?
    false
  end

  # TODO: teardown
  #         udevadm control --exit
end
