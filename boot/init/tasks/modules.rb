class Tasks::Modules < Task
  MODULES_PATH = "/lib/modules"
  def initialize(*modules)
    add_dependency(:Files, MODULES_PATH)
    add_dependency(:Target, :Environment)
    add_dependency(:Mount, "/proc")
    # May be required for input or display modules
    Targets[:Graphics].add_dependency(:Task, self)
    @modules = modules
  end

  def run()
    System.write("/proc/sys/kernel/modprobe", System.which("modprobe"))
    @modules.each do |mod|
      begin
        System.run("modprobe", mod)
      rescue System::CommandError
        $logger.warn("Kernel module #{mod} failed to load.")
      end
    end
  end
end
