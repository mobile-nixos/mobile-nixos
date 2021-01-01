# Extremely minimal and naïve arguments parsing.
module Args
  @@parsed = nil

  def self.get(key, default = nil)
    parse[:values][key] or default
  end

  def self.unused()
    parsed[:unused]
  end

  def self.parse()
    return @@parsed if @@parsed

    argv = ARGV.dup
    unused = []

    # Default values.
    # `nil` means it expects a parameter.
    # `false` means it's a boolean toggle without parameter.
    values = {}
    while argv.length > 0
      arg = argv.shift
      if arg.match(/^--help$/)
        # Assumes the programmer will add it
        begin
          print_help
        rescue
          $stderr.puts "Sorry, no help defined."
        end
        exit 0
      elsif arg.match(/^--/)
        key = arg.sub(/^--/, "").gsub("-", "_").to_sym
        if argv.length > 0 && !argv[0].match(/^--/)
          values[key] = argv.shift
        else
          values[key] = true
        end
      else
        unused << arg
      end
    end

    @@parsed = {
      unused: unused,
      values: values,
    }
  end
end
