# Mounts mount point
class Tasks::Mount < Task
  attr_reader :depends
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
    $logger.debug("Registering Mount task for mount point #{mount_point} #{instance.inspect}")
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

  def initialize(source, mount_point=nil, depends: [], **named)
    @depends = depends.map do |dep|
      File.join(Tasks::SwitchRoot::SYSTEM_MOUNT_POINT, dep)
    end
    @named = named
    if mount_point
      @source = source
      @mount_point = mount_point

      # Only add device dependencies for non-bind-mount absolute path.
      # Otherwise we would wait on the file "tmpfs" for tmpfs, and such.
      if @source.match(%{^/}) && !bind_mount?()
        add_dependency(:Devices, @source)
      end

      if bind_mount?()
        @source = File.join(Tasks::SwitchRoot::SYSTEM_MOUNT_POINT, @source)
        add_dependency(:Files, @source)
      end
    else
      @mount_point = @source
      @source = named[:type]
    end

    add_dependency(:Target, :Environment)
    self.class.register(@mount_point, self)
  end

  def run()
    if bind_mount?() && !File.directory?(source)
      # When bind mounting a file, create a file
      FileUtils.mkdir_p(File.dirname(mount_point))
      File.write(mount_point, "")
    else
      # Otherwise, create the target mount dir
      FileUtils.mkdir_p(mount_point)
    end
    System.mount(source, mount_point, **@named)
  end

  def type
    @named[:type]
  end

  def options()
    @named[:options] or []
  end

  def bind_mount?()
    options.include?("bind")
  end

  def refresh_lvm()
    unless System.which("lvm").nil? then
      begin
        ENV["LVM_SUPPRESS_FD_WARNINGS"] = "1"
        System.run("lvm", "vgchange", "--activate=y")
        ENV["LVM_SUPPRESS_FD_WARNINGS"] = nil
        System.run("udevadm", "trigger", "--action=add")
      rescue System::CommandError => e
        $logger.info(e.to_s)
      end
    end
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

      # Already mounted?
      # (Could be e.g. mounted beforehand or mounted by the kernel implicitly)
      return true if Mounting.mountpoint?(@mount_point)

      if task
        task.refresh_lvm
        task.ran
      end
    end

    def depends_on?(other)
      unless task
        $logger.warn("Missing Mount task for mount point #{@mount_point}")
        return false
      end

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
