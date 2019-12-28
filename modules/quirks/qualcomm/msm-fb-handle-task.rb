class Tasks::MSMFBHandle < SingletonTask
  def initialize()
    Targets[:Graphics].add_dependency(:Task, self)
    add_dependency(:Task, Tasks::Graphics.instance)
  end

  def run()
    @pid = System.spawn("msm-fb-handle")
  end

  # FIXME: cleanup when cleanup is implemented
end
