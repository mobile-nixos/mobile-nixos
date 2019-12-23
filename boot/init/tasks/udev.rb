# Runs udev daemon
class Tasks::UDev < SingletonTask
  def initialize()
    add_dependency(:SingletonTask, :Environment)
    add_dependency(:Files, "/dev/null")
    add_dependency(:Files, "/proc/cmdline")
    @pid = nil
  end

  def udevadm(*args)
    System.run("udevadm", *args)
  end

  def run()
    @pid = spawn("systemd-udevd", "--daemon")
    udevadm("trigger", "--action=add")
    udevadm("settle")
  end

  # TODO: teardown
  #         udevadm control --exit
end
