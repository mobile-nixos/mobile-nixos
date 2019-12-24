module Mounting
  def self.auto_depend_mount_points(mount_points)
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
  end

  # Creates tasks to mount all special mount points.
  # Dependencies on other mount points is being handled here.
  def self.create_special_mount_points()
    # Create all mount points.
    mount_points = Configuration["nixos"]["boot"]["specialFileSystems"].map do |mount_point, config|
      task = Tasks::Mount.new(
        mount_point,
        type: config["fsType"],
        options: config["options"],
      )

      [mount_point, task]
    end.to_h
    auto_depend_mount_points(mount_points)
  end

  # Creates tasks to mount all mount points required for boot.
  # Dependencies on other mount points is being handled here.
  def self.create_boot_mount_points()
    mount_points = Configuration["bootFileSystems"].map do |mount_point, config|
      mount_point = File.join("/mnt", mount_point)

      device = 
        if config["label"]
          "/dev/disk/by-label/#{config["label"]}"
        else
          config["device"]
        end

      options = config["options"].reject { |str| str.match(/^x-nixos\./) }

      task = Tasks::Mount.new(
        device,
        mount_point,
        type: config["fsType"],
        options: options,
      )

      # TODO: Handle failures gracefully
      # init_fail FFFF00 root_mount_failure "Could not mount root filesystem"

      # TODO: Add autoResize handling here!
      # (It will add a dependency on its own task, to the mount task.)
      # (Its own task is a new task type.)

      # Makes sure switching root waits until *all* mount points needed for
      # boot are fulfilled.
      Targets[:SwitchRoot].add_dependency(:Mount, mount_point)

      [mount_point, task]
    end.to_h
    auto_depend_mount_points(mount_points)
  end
end


