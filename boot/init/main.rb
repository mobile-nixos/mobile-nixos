begin
# TODO: Allow defining depending on stage-0/stage-1.
STAGE = 1

log("************************")
log("* Mobile NixOS stage-#{STAGE} *")
log("************************")
log("")
log("Built for device #{Configuration["device"]["name"]}")
log("")

# This file is a hard-coded map of non-implicit tasks.
# To these tasks, add all Singleton tasks found under tasks/*

# Without any added dependency, show a first splash ASAP
Tasks::Splash.new("stage-0")

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

Tasks::Splash.new("stage-1")
  .add_dependency(:Target, :Devices)

Tasks::Modules.new(*Configuration["kernel"]["modules"])

Tasks::go()

$logger.fatal("Tasks all ran, but we're still here...")
System.failure("did_not_switch", color: "ff0000")

rescue => e
  3.times do
    $logger.fatal("********************")
  end
  $logger.fatal("Handling exception")
  $logger.fatal(e.inspect)
  $logger.fatal("`init` will exit and the kernel will crash.")
  $logger.fatal("********************")
  # Leave some time for the $logger.fatals to flush before the kernel crashes.
  sleep(1)

  exit 99
end
