begin
# TODO: Allow defining depending on stage-0/stage-1.
STAGE = 1

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
Tasks::Splash.new("/etc/logo.svg")

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
System.failure("did_not_switch", color: "ff0000")

rescue => e
  System.sad_phone("765300", "Uncaught Exception", e.inspect)
  3.times do
    $logger.fatal("********************")
  end
  $logger.fatal("Handling exception")
  $logger.fatal(e.inspect)
  $logger.fatal("`init` will exit and the kernel will crash.")
  $logger.fatal("********************")
  # Leave some time for the $logger.fatals to flush before the kernel crashes.
  sleep(1)
  System.shell if System.respond_to?(:shell)

  # Users with access to serial debug may prefer crashing to the bootloader.
  # Though, crashing the kernel is *required* for console ramoops to be present.
  if Configuration["boot"]["crashToBootloader"] then
    System.run("reboot bootloader")
  else
    exit 99
  end
end
