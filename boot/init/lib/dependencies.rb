module Dependencies
  class BaseDependency
    def fulfilled?()
      true
    end

    def name()
      self.class.name
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
  end
end
