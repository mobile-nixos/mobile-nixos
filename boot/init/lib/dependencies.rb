module Dependencies
  class BaseDependency
    def fulfilled?()
      true
    end

    def name()
      self.class.name
    end

    # User-facing name
    def pretty_name()
      name
    end

    def depends_on?(other)
      raise "#{self.class.name} has to implement #depends_on?"
    end

    # Same as name, but with the object_id appended.
    def to_s()
      name + "<0x#{object_id.to_s(16)}>"
    end
  end

  class Task < BaseDependency
    def initialize(instance)
      @instance = instance
    end

    def fulfilled?()
      if @instance.ran
        true
      else
        $logger.debug(" -> Dependency #{name} unfulfilled? (task #{@instance.inspect} hasn't run yet)")
        false
      end
    end

    def depends_on?(other)
      @instance.depends_on?(other)
    end

    def name()
      super + "(#{@instance.name})"
    end
  end

  # When any of the dependencies given have been fulfilled, this dependency
  # will be fulfilled.
  class Any < BaseDependency
    def initialize(*dependencies)
      @dependencies = dependencies
    end

    def fulfilled?()
      @dependencies.any? { |dependency| dependency.fulfilled? }
    end

    def depends_on?(other)
      @dependencies.any? { |dependency| dependency.depends_on?(other) }
    end

    def name()
      super + "(#{@dependencies.map(&:name).join(", ")})"
    end
  end

  class Files < BaseDependency
    def initialize(*patterns)
      @patterns = *patterns
    end

    def fulfilled?()
      if @patterns.all? { |pattern| Dir.glob(pattern).count > 0 }
        true
      else
        $logger.debug do
          patterns = @patterns.reject do |pattern|
            Dir.glob(pattern).count > 0
          end.join(", ")

          " -> Dependency #{name} unfulfilled? (Pattern #{patterns} does not match paths)"
        end
        false
      end
    end

    # It is unknown what creates the file.
    # For mount points, prefer the +Mount+ dependency type.
    def depends_on?(other)
      false
    end

    def name()
      super + "(#{@patterns.join(", ")})"
    end

    def pretty_name()
      if @patterns.length == 1
        "File '#{@patterns.first}'"
      else
        "Files #{@patterns.map{|f| "'#{f}'"}.join(", ")}"
      end
    end
  end

  # Checks in sysfs for the given network interface names.
  class NetworkInterface < Files
    def initialize(*names)
      @names = names
      super(*names.map { |name| File.join("/sys/class/net", name) })
    end

    def name()
      super + "(#{@names.join(", ")})"
    end
  end

  class Devices < Files
    def pretty_name()
      if @patterns.length == 1
        "Device '#{@patterns.first}'"
      else
        "Devices #{@patterns.map{|f| "'#{f}'"}.join(", ")}"
      end
    end
  end

  class Target < BaseDependency
    def initialize(name)
      @name = name.to_sym
    end

    def fulfilled?()
      task.ran
    end

    def depends_on?(other)
      task.depends_on?(other)
    end

    def task()
      Targets[@name]
    end

    def name()
      super + "(#{@name})"
    end
  end
end
