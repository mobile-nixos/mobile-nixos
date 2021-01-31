class Tasks::RunGui < SingletonTask
  def initialize()
    add_dependency(:Target, :Graphics)
    add_dependency(:Mount, "/run")
    add_dependency(:Files, "/dev/input")

    # Ensures networking and SSH works
    add_dependency(:Target, :Networking)
    add_dependency(:Task, Tasks::DropbearSSHD.instance)

    # Ensure this runs before SwitchRoot happens.
    # Otherwise this could never be ran!
    Tasks::SwitchRoot.instance.add_dependency(:Task, self)
    add_dependency(:Task, Tasks::SetupGadgetMode.instance)

    # Ensure shell runs once before.
    if Tasks.const_defined?(:RunShell)
      add_dependency(:Task, Tasks::RunShell.instance)
      Tasks::RunShell.instance.add_dependency(
        :Task,
        Tasks::SetupGadgetMode.instance
      )
    end
  end

  def run()
    # Free up the framebuffer / DRM context
    Progress.kill()

    System.run(LOADER, "/applets/tdm-gui.mrb")
    
    # This `raise` shouldn't really happen as `System#run` will raise
    # if the program exits non-zero.
    # Though, let's nor fail in weird ways, let's be explicit.
    raise "Target Disk Mode GUI exited."
  end

  def ux_priority()
    -10000
  end
end
