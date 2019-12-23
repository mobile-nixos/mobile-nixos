# TODO: Allow defining depending on stage-0/stage-1.
STAGE = 1
FAILURE_SLEEP = 10

$configuration = JSON.parse(File.read("/etc/boot/config"));

log("************************")
log("* Mobile NixOS stage-#{STAGE} *")
log("************************")
log("")
log("Built for device #{$configuration["device"]["name"]}")
log("")

Tasks::Splash.new("stage-0")
Tasks::Symlink.new("/proc/mounts", "/etc/mtab")
Tasks::Mount.new("/dev/pts", type: "devpts")
  .add_dependency(:Files, "/dev/")
Tasks::Mount.new("/dev", type: "devtmpfs")
Tasks::Mount.new("/proc", type: "proc")
Tasks::Mount.new("/sys", type: "sysfs")
[
  "/run",
  "/etc/udev",
  "/var/log",
].each do |dir|
  Tasks::Directory.new(dir)
end

Tasks::Splash.new("stage-1")
  .add_dependency(:SingletonTask, :UDev)

Tasks::Mount.new($configuration["root"]["device"], "/mnt")
Tasks::Modules.new(*$configuration["kernel"]["modules"])

Tasks::go()

$logger.fatal("Tasks all ran, but we're still here...")
$logger.fatal("Sleeping for #{FAILURE_SLEEP} seconds then exiting...")
sleep(FAILURE_SLEEP)
exit(99)
