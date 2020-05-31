class Tasks::MsmFbNotify < SingletonTask
  def initialize()
    Targets[:SwitchRoot].add_dependency(:Task, self)
    add_dependency(:Mount, "/sys")
  end

  def run()
    System.write("/sys/class/graphics/fb0/blank", "0")
  end
end
