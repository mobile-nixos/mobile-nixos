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
  end

  def run()
    mode = File.read("/sys/class/graphics/fb0/modes")
    log("Setting framebuffer mode to: #{mode}")
    File.write("/sys/class/graphics/fb0/mode", mode)
  end
end
