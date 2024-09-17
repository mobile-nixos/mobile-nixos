class Tasks::Modules < Task
  MODULES_PATH = "/lib/modules"
  SYS_MODPROBE_PATH = "/proc/sys/kernel/modprobe"
  def initialize(*modules)
    add_dependency(:Files, MODULES_PATH)
    add_dependency(:Target, :Environment)
    add_dependency(:Mount, "/proc")
    # May be required for input or display modules
    Targets[:Graphics].add_dependency(:Task, self)
    @modules = modules
  end

  def run()
    unless File.exist?(SYS_MODPROBE_PATH)
      $logger.warn("Could not tell the path to modprobe to the kernel.")
      $logger.warn("('#{SYS_MODPROBE_PATH}' is missing.)")
      return
    end
    System.write(SYS_MODPROBE_PATH, System.which("modprobe"))
    @modules.each do |mod|
      begin
        System.run("modprobe", mod)
      rescue System::CommandError
        $logger.warn("Kernel module #{mod} failed to load.")
      end
    end
  end
end
