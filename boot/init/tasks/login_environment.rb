# Adds a minimal set of files required for logging-in.
class Tasks::LoginEnvironment < SingletonTask
  def initialize()
    add_dependency(:Boot)
  end

  def run()
    # Basic stuff expected by shells and logins
    FileUtils.mkdir_p(
      "/etc",
      "/var/log",
    )
    File.write("/etc/shells", "/bin/sh\n")
    File.write("/etc/passwd", "root:*:0:0:root:/root:/bin/sh\n")
    File.write("/etc/nsswitch.conf", "passwd: files\n")
    File.write("/var/log/lastlog", "")
  end
end
