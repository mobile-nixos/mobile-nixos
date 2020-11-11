# Ensures graphics have been initialized and are ready to be used.
#
# Currently this only handles the "legacy fbdev" style of framebuffers.
class Tasks::Graphics < SingletonTask
  def initialize()
    add_dependency(
      :Files,
      "/sys/class/graphics/fb0/mode",
      "/sys/class/graphics/fb0/modes",
    )
    # This is only incidental to the fact that /dev/fb0 wouldn't exist for
    # users of the "Graphics" dependency.
    add_dependency(:Mount, "/dev")

    # Make the Graphics target depend on this task.
    Targets[:Graphics].add_dependency(:Task, self)
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
