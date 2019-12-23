# Mounts mount point
class Tasks::Mount < Task
  attr_reader :source
  attr_reader :mount_point

  def initialize(source, mount_point=nil, **named)
    @named = named
    if mount_point
      @source = source
      @mount_point = mount_point
      add_dependency(:Files, source)
    else
      @source = named[:type]
      @mount_point = source
    end
    add_dependency(:SingletonTask, :Environment)
  end

  def run()
    FileUtils.mkdir_p(mount_point)
    System.mount(source, mount_point, **@named)
  end

  def type
    @named[:type]
  end

  def name()
    "#{super}(#{source}, #{mount_point}, #{@named.inspect})"
  end
end
