class Tasks::Modules < Task
  MODULES_PATH = "/lib/modules"
  def initialize(*modules)
    add_dependency(:Files, MODULES_PATH)
    add_dependency(:Target, :Environment)
    @modules = modules
  end

  def run()
    @modules.each do |mod|
      begin
        System.run("modprobe", mod)
      rescue System::CommandError
        $logger.warn("Kernel module #{mod} failed to load.")
      end
    end
  end
end
