class Tasks::MsmDwc3OtgSwitch < SingletonTask
  def initialize()
    Targets[:SwitchRoot].add_dependency(:Task, self)
    add_dependency(:Mount, "/sys")
  end

  def run()
    System.write("/sys/module/dwc3_msm/parameters/otg_switch", "1")
  end
end
