# Ensures graphics have been initialized and are ready to be used.
class Tasks::Graphics < SingletonTask
  def initialize()
    add_dependency(
      :Any,
      Dependencies::Task.new(FBDev.instance),
      Dependencies::Task.new(DRM.instance),
    )

    # Make the Graphics target depend on this task.
    Targets[:Graphics].add_dependency(:Task, self)
  end

  def run()
    # no-op
  end

  def ux_priority()
    -100
  end
end

# Handles the "legacy fbdev" style of framebuffers.
class Tasks::Graphics::FBDev < SingletonTask
  def initialize()
    add_dependency(
      :Files,
      "/sys/class/graphics/fb0/mode",
      "/sys/class/graphics/fb0/modes",
    )
    # This is only incidental to the fact that /dev/fb0 wouldn't exist for
    # users of the "Graphics" dependency.
    add_dependency(:Mount, "/dev")
  end

  def run()
    mode = File.read("/sys/class/graphics/fb0/modes")
    log("Setting framebuffer mode to: #{mode}")
    System.write("/sys/class/graphics/fb0/mode", mode)
  end

  def ux_priority()
    -100
  end
end

# Handles DRM
# (Does nothing, only handles dependencies)
class Tasks::Graphics::DRM < SingletonTask
  def initialize()
    add_dependency(
      :Files,
      "/dev/dri/card0",
    )
    add_dependency(:Mount, "/dev")
  end

  def run()
    # no-op
  end

  def ux_priority()
    -100
  end
end
