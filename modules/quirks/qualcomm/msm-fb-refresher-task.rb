class Tasks::MSMFBRefresher < SingletonTask
  def initialize()
    Targets[:Graphics].add_dependency(:Task, self)
    add_dependency(:Task, Tasks::Graphics.instance)
  end

  def run()
    @pid = System.spawn("msm-fb-refresher", "--loop")
  end

  # FIXME: cleanup when cleanup is implemented
end
