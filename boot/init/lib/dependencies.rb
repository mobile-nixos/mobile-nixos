module Dependencies
  class BaseDependency
    def fulfilled()
      true
    end
  end

  class Boot < BaseDependency
  end

  class SingletonTask < BaseDependency
    def initialize(symbol)
      @symbol = symbol
    end
    def fulfilled()
      Tasks.const_get(@symbol).instance.ran
    end
  end

  class Files < BaseDependency
    def initialize(*patterns)
      @patterns = *patterns
    end
    def fulfilled()
      @patterns.all? do |pattern|
        Dir.glob(pattern).count > 0
      end
    end
  end
end
