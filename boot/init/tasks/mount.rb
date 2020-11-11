# Mounts mount point
class Tasks::Mount < Task
  attr_reader :source
  attr_reader :mount_point

  class ExistingMountTask < StandardError
  end

  def self.normalize_mountpoint(path)
    path = path.split("/").join("/")
    path = "/" if path == ""
    path
  end

  def self.register(mount_point, instance)
    mount_point = normalize_mountpoint(mount_point)
    @registry ||= {}
    unless @registry[mount_point].nil? then
      raise ExistingMountTask.new("Mount point task for '#{mount_point}' already exists.")
    end
    @registry[mount_point] = instance
  end

  def self.registry()
    @registry
  end

  def initialize(source, mount_point=nil, **named)
    @named = named
    if mount_point
      @source = source
      @mount_point = mount_point
      # Only add a dependency for an absolute path.
      # Otherwise we would wait on the file "tmpfs" for tmpfs, and such.
      if source.match(%{^/})
        add_dependency(:Devices, source)
      end
    else
      @source = named[:type]
      @mount_point = source
    end
    add_dependency(:Target, :Environment)
    self.class.register(@mount_point, self)
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

module Dependencies
  class Mount < BaseDependency
    def initialize(mount_point)
      @mount_point = Tasks::Mount.normalize_mountpoint(mount_point)
    end

    def fulfilled?()
      unless task
        $logger.warn("Missing Mount task for mount point #{@mount_point}")
      end
      task && task.ran
    end

    def depends_on?(other)
      task.depends_on?(other)
    end

    def task()
      Tasks::Mount.registry[@mount_point]
    end

    def name()
      super + "(#{@mount_point})"
    end

    def pretty_name()
      "Mounting '#{@mount_point}'"
    end
  end
end
