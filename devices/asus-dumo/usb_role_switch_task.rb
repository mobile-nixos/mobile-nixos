class Tasks::UsbRoleSwitchTask < SingletonTask
  def initialize()
    Tasks::SetupGadgetMode.instance.add_dependency(:Task, self)
    add_dependency(:Mount, "/sys")
  end

  def run()
    System.write("/sys/class/usb_role/fe800000.usb-role-switch/role", "device")
  end
end
