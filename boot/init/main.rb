# FIXME: Allow overriding $logger.level = Logger::DEBUG at build-time
# Otherwise early logging will be lost.
$logger.level = Logger::DEBUG

# TODO: Allow defining depending on stage-0/stage-1.
STAGE = 1
log("************************")
log("* Mobile NixOS stage-#{STAGE} *")
log("************************")
log("")
log("TODO: embed build information...")
log("")

def cat(*files)
  files.map do |file|
    File.read(file)
  end.join("")
end

def prepare_mounts()
  FileUtils.mkdir_p(
    "/proc",
    "/sys",
    "/dev",
    "/tmp",
    "/run",
    "/lib",
    "/mnt",
    "/etc/udev",
    "/var/log",
  )
  System.mount("/dev", type: "devtmpfs")
  System.mount("/proc", type: "proc")
  System.mount("/sys", type: "sysfs")

  FileUtils.mkdir_p("/dev/pts")
  System.mount("/dev/pts", type: "devpts")
end

def prepare_shell_files()
  # Basic stuff expected by shells and logins
  File.write("/etc/shells", "/bin/sh\n")
  File.write("/etc/passwd", "root:*:0:0:root:/root:/bin/sh\n")
  File.write("/etc/nsswitch.conf", "passwd: files\n")
  File.write("/var/log/lastlog", "")
end

def prepare_framebuffer()
  mode = File.read("/sys/class/graphics/fb0/modes")
  log("Setting framebuffer mode to: #{mode}")
  File.write("/sys/class/graphics/fb0/mode", mode)
end

def show_splash(name)
  System.run("ply-image", "/splash.#{name}.png")
end

# Loads a basic environment.
# This is used mainly to make LD_LIBRARY_PATH valid, and additionally
# point PATH to extraUtils.
UDev.simple_load_environment("/etc/udev/rules.d/00-env.rules")

prepare_mounts()
# FIXME: Set logger level according to /proc/cmdline
$logger.level = Logger::DEBUG

prepare_shell_files()
prepare_framebuffer()
show_splash("stage-0")

while true do
  log("Hello from this init!")
  sleep(60)
end
