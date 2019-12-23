# Mounts mount point
class Tasks::Mount < Task
  def initialize(*args)
    add_dependency(:SingletonTask, :Environment)
    @args = args
  end

  def run()
    args = @args.dup
    dir = args.first
    FileUtils.mkdir_p(dir)
    System.mount(*args)
  end

  def name()
    "#{super}(#{@args.inspect})"
  end
end
