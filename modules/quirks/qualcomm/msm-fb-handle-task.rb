class Tasks::MSMFBHandle < SingletonTask
  def initialize()
    add_dependency(:SingletonTask, :Graphics)
  end

  def run()
    @pid = System.spawn("msm-fb-handle")
  end

  # FIXME: cleanup when cleanup is implemented
end
