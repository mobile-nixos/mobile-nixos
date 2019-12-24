# TODO: Allow defining depending on stage-0/stage-1.
STAGE = 1
FAILURE_SLEEP = 10

log("************************")
log("* Mobile NixOS stage-#{STAGE} *")
log("************************")
log("")
log("Built for device #{Configuration["device"]["name"]}")
log("")

Tasks::Splash.new("stage-0")
Tasks::Symlink.new("/proc/mounts", "/etc/mtab")

# Create all mount points.
mount_points = Configuration["nixos"]["boot"]["specialFileSystems"].map do |mount_point, config|
  task = Tasks::Mount.new(
    mount_point,
    type: config["fsType"],
    options: config["options"],
  )

  [mount_point, task]
end.to_h

mount_points.each do |_, target|
  mount_points.each do |_, higher|
    next if target == higher
    # We're using +#mount_point+ on the tasks to use the normalized mount point
    # names.
    # If the higher mount point is found at the start of the target mount point.
    # This will match /dev for /dev/shm, but not the reverse.
    if target.mount_point.index(higher.mount_point) == 0 then
      $logger.debug("#{target.mount_point} is under #{higher.mount_point}")
      target.add_dependency(:Mount, higher.mount_point)
    end
  end
end

[
  "/etc/udev",
  "/var/log",
].each do |dir|
  Tasks::Directory.new(dir)
end

Tasks::Splash.new("stage-1")
  .add_dependency(:SingletonTask, :UDev)

Tasks::Mount.new(Configuration["root"]["device"], "/mnt")
Tasks::Modules.new(*Configuration["kernel"]["modules"])

Tasks::go()

$logger.fatal("Tasks all ran, but we're still here...")
$logger.fatal("Sleeping for #{FAILURE_SLEEP} seconds then exiting...")
sleep(FAILURE_SLEEP)
exit(99)
