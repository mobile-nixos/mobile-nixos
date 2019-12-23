module Dependencies
  class BaseDependency
    def fulfilled()
      true
    end

    def name()
      self.class.name
    end
  end

  class Boot < BaseDependency
  end

  class Task < BaseDependency
    def initialize(instance)
      @instance = instance
    end

    def fulfilled()
      if @instance.ran
        true
      else
        $logger.debug(" -> Dependency #{name} unfulfilled (task #{@instance.inspect} hasn't run yet)")
        false
      end
    end
  end

  class SingletonTask < BaseDependency
    def initialize(symbol)
      @symbol = symbol
    end

    def fulfilled()
      if Tasks.const_get(@symbol).instance.ran
        true
      else
        $logger.debug(" -> Dependency #{name} unfulfilled (task #{@symbol} hasn't run yet)")
        false
      end
    end
  end

  class Files < BaseDependency
    def initialize(*patterns)
      @patterns = *patterns
    end

    def fulfilled()
      if @patterns.all? { |pattern| Dir.glob(pattern).count > 0 }
        true
      else
        $logger.debug do
          @patterns.each do |pattern|
            unless Dir.glob(pattern).count > 0
              " -> Dependency #{name} unfulfilled (Pattern #{pattern} does not match paths)"
            end
          end
        end
        false
      end
    end
  end
end
