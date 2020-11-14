class Tasks::Crash < SingletonTask
  def initialize()
    # Runs before SwitchRoot
    Targets[:SwitchRoot].add_dependency(:Task, self)
    # And after /mnt is available
    add_dependency(:Mount, "/mnt")
  end

  def run()
    raise "This is an exception from init!"
  end
end
