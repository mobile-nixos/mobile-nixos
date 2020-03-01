# Extremely minimal and naïve arguments parsing.
module Args
  @@parsed = nil

  def self.define(defaults)
    self.const_set(:DEFAULTS, defaults)
    self.parse
  end

  def self.get(key)
    if DEFAULTS.has_key?(key)
      parse[:values][key]
    else
      raise "Unknown argument #{key} requested."
    end
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
    values = DEFAULTS.dup
    while argv.length > 0
      arg = argv.shift
      if arg.match(/^--help$/)
        print_help
        exit 0
      elsif arg.match(/^--/)
        key = arg.sub(/^--/, "").gsub("-", "_").to_sym
        if values.has_key?(key)
          if values[key] == nil
            if argv.length == 0
              raise "Expected a value for #{arg}."
            end
            values[key] = argv.shift
          else
            values[key] = true
          end
        else
          raise "Unexpected parameter #{arg}."
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

  def self.print_help()
    puts <<EOF
Usage: $PROGRAM_NAME

#{
  DEFAULTS.map do |k, default|
    [
    "  --#{k.to_s.gsub("_", "-")}",
    if default == nil
      "<value>"
    else
      nil
    end
    ].compact.join(" ")
  end.join("\n")
}
EOF
  end
end
