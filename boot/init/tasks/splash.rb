# Adds a minimal set of files required for logging-in.
class Tasks::Splash < Task
  attr_reader :image

  def initialize(image)
    add_dependency(:Target, :Graphics)
    @image = image
  end

  def run()
    begin
    System.run("ply-image", "/splash.#{image}.png")
    rescue System::CommandError
    end
  end

  def name()
    "#{super}(#{image})"
  end
end
