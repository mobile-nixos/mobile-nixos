# TODO: Allow defining depending on stage-0/stage-1.
STAGE = 1
FAILURE_SLEEP = 10

log("************************")
log("* Mobile NixOS stage-#{STAGE} *")
log("************************")
log("")
log("TODO: embed build information...")
log("")

Tasks::Splash.new("stage-0")
Tasks::Symlink.new("/proc/mounts", "/etc/mtab")
Tasks::Mount.new("/dev/pts", type: "devpts")
  .add_dependency(:Files, "/dev/")
Tasks::Mount.new("/dev", type: "devtmpfs")
Tasks::Mount.new("/proc", type: "proc")
Tasks::Mount.new("/sys", type: "sysfs")
[
  "/proc",
  "/sys",
  "/dev",
  "/tmp",
  "/run",
  "/lib",
  "/mnt",
  "/etc/udev",
  "/var/log",
].each do |dir|
  Tasks::Directory.new(dir)
end

# FIXME: depend on udev running
Tasks::Splash.new("stage-1")

Tasks::Mount.new("/dev/disks/by-label/NIXOS", "/mnt")

Tasks::go()

$logger.fatal("Tasks all ran, but we're still here...")
$logger.fatal("Sleeping for #{FAILURE_SLEEP} seconds then exiting...")
sleep(FAILURE_SLEEP)
exit(99)
