module UDev
  # Loads a simplified `ENV{k}="v"` udev rules file.
  # This is *not* a comprehensive parser!!
  # This is intended to be used for loading the environment as described by
  # udev rules.
  def self.simple_load_environment(file)
    rules = File.read(file).strip.split("\n")
    rules.each do |line|
      data = line.match(/\s*ENV{([^}]+)}="(.*)"$/)
      next unless data
      ENV[data[1]] = data[2]
    end
  end
end
