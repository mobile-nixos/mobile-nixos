# Adds a minimal set of files required for logging-in.
class Tasks::Splash < Task
  attr_reader :image

  def initialize(image)
    add_dependency(:SingletonTask, :Graphics)
    @image = image
  end

  def run()
    System.run("ply-image", "/splash.#{image}.png")
  end

  def name()
    "#{super}(#{image})"
  end
end
