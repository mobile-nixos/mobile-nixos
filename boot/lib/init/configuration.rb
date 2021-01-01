# Handles lazy-loading the configuration, and giving a value for a given key.
module Configuration
  def self.[](key)
    @configuration ||= JSON.parse(File.read("/etc/boot/config"));
    @configuration[key]
  end
end
