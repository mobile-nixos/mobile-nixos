# Adds a minimal set of files required for logging-in.
class Tasks::LoginEnvironment < SingletonTask
  def initialize()
  end

  def run()
    # Basic stuff expected by shells and logins
    FileUtils.mkdir_p(
      "/etc",
      "/var/log",
    )
    System.write("/etc/shells", "/bin/sh\n")
    System.write("/etc/passwd", "root:*:0:0:root:/root:/bin/sh\n")
    System.write("/etc/nsswitch.conf", "passwd: files\n")
    System.write("/var/log/lastlog", "")
  end
end
