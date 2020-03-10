# Adds a minimal set of files required for logging-in.
class Tasks::Splash < Task
  attr_reader :image

  def initialize(image)
    add_dependency(:Target, :Graphics)
    @image = image
  end

  def run()
    begin
      System.run($PROGRAM_NAME, "/applets/boot-splash.mrb", image)
    # Don't fail the boot if the splash fails
    rescue System::CommandError
    end
  end

  def name()
    "#{super}(#{image})"
  end

  def ux_priority()
    -100
  end
end
