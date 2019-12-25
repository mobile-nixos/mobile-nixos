class Tasks::MSMFBRefresher < SingletonTask
  def initialize()
    add_dependency(:SingletonTask, :Graphics)
  end

  def run()
    @pid = System.spawn("msm-fb-refresher", "--loop")
  end

  # FIXME: cleanup when cleanup is implemented
end
