# Waits until /run is available to start the progress socket.
class Tasks::ProgressSocket < SingletonTask
  def initialize()
    add_dependency(:Mount, "/run")
  end

  def run()
    Progress.start()
  end

  def ux_priority()
    -100
  end
end
