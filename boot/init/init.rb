begin
STAGE = Configuration["stage"]

LOADER = "/loader"

log("************************")
log("* Mobile NixOS stage-#{STAGE} *")
log("************************")
log("")
# Since we would like to *somewhat* guesstimate how long it took to get to the
# actual init program, we can print the CLOCK_MONOTONIC at startup.
# It's not perfect, but that gets us halfway there I guess.
log("init started ~#{"%.6f" % (Process.clock_gettime(Process::CLOCK_MONOTONIC))}s after kernel boot time.")
log("Built for device #{Configuration["device"]["name"]}")
log("")

# This file is a hard-coded map of non-implicit tasks.
# To these tasks, add all Singleton tasks found under tasks/*

# Without any added dependency, show a first splash ASAP
Tasks::Splash.instance()

# Some software (mainly extfs tools) bark angrily and fail when this is missing.
Tasks::Symlink.new("/proc/mounts", "/etc/mtab")

Mounting.create_special_mount_points()
Mounting.create_boot_mount_points()

[
  "/etc/udev",
  "/var/log",
].each do |dir|
  Tasks::Directory.new(dir)
end

Tasks::Modules.new(*Configuration["kernel"]["modules"])

Tasks::go()

$logger.fatal("Tasks all ran, but we're still here...")
System.failure(
  "INIT_FAILED_SWITCH",
  "Boot process failed to switch to stage-2",
  "The stage-1 init did not detect any failure condition, but failed to switch to stage-2.\n\n" +
  "It shouldn't happen, yet here we are.",
  color: "ff0000"
)

rescue => e
  # Then fail
  System.failure("INIT_EXCEPTION", "Uncaught Exception", e.inspect, color: "765300", status: 99)
end
