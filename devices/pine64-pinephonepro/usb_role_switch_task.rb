class Tasks::UsbRoleSwitchTask < SingletonTask
  def initialize()
    Tasks::SetupGadgetMode.instance.add_dependency(:Task, self)
    add_dependency(:Mount, "/sys")
  end

  # Toggle the role switch, it has been observed (by others online) that it
  # *may* help in some situations, compared to just setting it to "device".
  def run()
    if File.exist?("/sys/class/usb_role/fe800000.usb-role-switch/role")
      System.write("/sys/class/usb_role/fe800000.usb-role-switch/role", "host")
      sleep(0.1)
      System.write("/sys/class/usb_role/fe800000.usb-role-switch/role", "device")
    end
  end
end
