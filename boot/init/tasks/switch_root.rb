class Tasks::SwitchRoot < SingletonTask
  # Relative to root.
  DEFAULT_SYSTEM_LINK = "/nix/var/nix/profiles/system"

  # Where the system will be mounted.
  SYSTEM_MOUNT_POINT = "/mnt"

  def initialize()
    add_dependency(:Task, Tasks::Splash.instance)
    add_dependency(:Target, :SwitchRoot)
    @target = SYSTEM_MOUNT_POINT

    # By default, with stage-0, we prefer using the generation kernel
    # This may be overriden by the user recovery user interface
    @use_generation_kernel = STAGE == 0
  end

  # Given a path name, without the leading SYSTEM_MOUNT_POINT, resolves
  # symlinks to get the real name of the file.
  # The returned path is not prefixed with SYSTEM_MOUNT_POINT either.
  def readlink_system(filename)
    # Resolve the full pathname
    loop do
      prev_filename = filename

      if File.symlink?(File.join(SYSTEM_MOUNT_POINT, prev_filename))
        filename = File.readlink(File.join(SYSTEM_MOUNT_POINT, prev_filename))

        # Relative link? Make absolute.
        unless filename.match(%r{^/})
          filename = File.join(File.dirname(prev_filename), filename)
        end
      end
      break if prev_filename == filename
    end

    filename
  end

  # Creates the generation selection list.
  def generate_selection()
    FileUtils.mkdir_p("/run/boot/")
    base = File.join(SYSTEM_MOUNT_POINT, DEFAULT_SYSTEM_LINK)
    selection = [
      base,
      *(Dir.glob(base + "-*").sort do |a, b|
        File.lstat(a).mtime <=> File.lstat(b).mtime
      end.reverse)
    ].map do |path|
      if path == base then
        {
          id: "$default",
          name: "Mobile NixOS - Default",
        }
      else
        date = File.lstat(path).mtime.strftime("%F")
        version_file = File.join(path, "nixos-version")
        version =
          if File.exist?(version_file)
            File.read(version_file)
          else
            nil
          end
        num = path.split("-")[-2]
        details = [
          date,
          version,
        ].compact.join(" - ")

        name = "Mobile NixOS ##{num} (#{details})"

        # This is the path we want to switch_root into.
        path = File.readlink(path)

        {
          id: path,
          name: name,
        }
      end
    end

    File.write("/run/boot/selection.json", selection.to_json)
  end

  # Boot the default generation.
  # This does either of:
  #
  #  * Booting the generation given in parameters
  #  * Booting the default system link.
  #  * Find the generation store path that needs to be rehydrated.
  #
  # This is *always* a sane default to fallback on.
  def default_generation()
    # Given as a command-line option, most likely from stage-0.
    generation_parameter = System.cmdline().grep(/^mobile-nixos.generation=/).first
    unless generation_parameter.nil?
      return generation_parameter.split("=", 2).last
    end

    # Given as a command-line option, from the bootloader (replacement for NixOS's stage-1)
    init_parameter = System.cmdline().grep(/^init=/).first
    if init_parameter == "init=/init" then
      $logger.info("Skipping '#{init_parameter}' cmdline parameter from quirky device...")
    else
      unless init_parameter.nil?
        $logger.info("Using '#{init_parameter}' cmdline parameter to select generation...")
        init_parameter = init_parameter.split("=", 2).last
        return init_parameter.rpartition("/").first
      end
    end

    # The default generation
    if File.symlink?(File.join(@target, DEFAULT_SYSTEM_LINK))
      $logger.info("Using '#{DEFAULT_SYSTEM_LINK}' default generation...")
      return DEFAULT_SYSTEM_LINK
    end

    # Otherwise, we need to re-hydrate a system!
    registration = File.join(@target, "nix-path-registration")
    if File.exist?(registration)
      $logger.info("Getting NixOS generation from nix-path-registration...")
      path = File.read(registration)
        .split("\n")
        .grep(%r{^/nix/store/[a-z0-9]+-nixos-system-})
        .first
      return path if path
    end

    System.failure("INIT_NOT_FOUND", "Stage-2 init not found", "Could not find init path for stage-2", color: "FF00FF")
  end

  # Pauses the boot to allow the user to select a generation.
  def choose_generation()
    generate_selection()

    # Synchronuously (pause the init code) show the selection applet.
    System.run(LOADER, "/applets/boot-selection.mrb")

    # Read data from the user
    data = JSON.parse(File.read("/run/boot/choice"))
    generation = data["generation"]
    @use_generation_kernel = data["use_generation_kernel"]

    # Why "$default" rather than passing a path?
    # Because there may be no generations folder. It's easier to cheat and
    # use "$default" and rely on the existing default "maybe rehydrate"
    # codepath.
    if generation == "$default"
      default_generation()
    else
      generation
    end
  end

  def selected_generation()
    return @selected_generation if @selected_generation

    if Hal::Recovery.wants_recovery?
      Tasks::Splash.instance.quit("Continuing to recovery menu")
      @selected_generation = choose_generation()
    else
      @selected_generation = default_generation()
      if will_kexec?()
        Tasks::Splash.instance.quit("Rebooting in generation kernel", sticky: true)
      else
        Tasks::Splash.instance.quit("Continuing to stage-2")
      end
    end
    @selected_generation
  end

  # If the system build exports a DTB file name to load, return the appropriate
  # command-line argument for `kexec`. Otherwise nil.
  def maybe_dtb()
    log("Looking for a DTB file...")

    mapping_path = generation_file("mobile-nixos/dtb-mapping.json", missing_allowed: true)
    unless mapping_path && File.exist?(mapping_path)
      log("  DTB: dtb-mapping.json not found... skipping DTB mapping...")
      return nil
    end

    log("  DTB: Mappings from: `#{mapping_path}`...")
    mapping = JSON.parse(File.read(mapping_path))

    # Work only off the first compatible name.
    # It is assumed that the loader uses the exact same scheme as the kernel
    # build does. If this assumption stops holding true, it will be a new
    # feature to implement.
    board_compatible = File.read("/proc/device-tree/compatible").split("\0").first
    log("  DTB: board_compatible: #{board_compatible}")

    desired_dtb = mapping[board_compatible]
    if desired_dtb
      log("  DTB: wants: #{desired_dtb}")
    else
      log("  DTB: no DTB mapping found for #{board_compatible}...")
      return nil
    end

    # The desired_dtb path is an absolute path in the mounted system.
    file = File.join(SYSTEM_MOUNT_POINT, desired_dtb)

    if File.exist?(file)
      log("  DTB: file `#{file}` found")
      "--dtb=#{forward_fdt_bootloader_info(file)}"
    else
      log("  DTB: file `#{file}` not found... skipping DTB mapping")
      nil
    end
  end

  # Given a path to a DTB file, merges required properties that the bootloader
  # has setup. It will additionally merge optional properties.
  def forward_fdt_bootloader_info(path)
    args = [
      "--print-header",
      "--copy-dtb", path,
      Configuration["stage-0"]["forward"]["nodes"].map {|path| [ "--forward-node", path] },
      Configuration["stage-0"]["forward"]["props"].map {|pair| [ "--forward-prop", *pair] },
    ].flatten
    log(" $ fdt-forward #{args.shelljoin}")
    dts = `fdt-forward #{args.shelljoin}`

    # Declare we booted using stage-0's kexec
    # And additional useful debugging data...
    dts << [
      "\n",
      "// Declare we booted using kexec",
      %Q{/ { mobile-nixos,stage-0; };},
      %Q{/ { mobile-nixos,stage-0,timestamp = #{Time.now.to_s.to_json}; };},
      %Q{/ { mobile-nixos,stage-0,uname = #{`uname -a`.to_json}; };},
      %Q{/ { mobile-nixos,stage-0,uptime = #{`uptime`.to_json}; };},
    ].join("\n")

    FileUtils.mkdir_p("/run/boot/")
    File.write("/run/boot/fdt.dts", dts)
    System.run("fdt-forward --to-dtb < /run/boot/fdt.dts > /run/boot/fdt.dtb")

    return "/run/boot/fdt.dtb"
  end

  def will_kexec?()
    # Only stage-0 bootloader-flavourd init will kexec.
    return false unless STAGE == 0

    # The user wants to use the generation's kernel
    return false unless @use_generation_kernel

    # AND if we find the required files.
    [
      "initrd",
      "kernel",
      "kernel-params",
    ]
      .map { |file| generation_file(file) }
      .map { |file| File.exist?(file) }
      .all?
  end

  def generation_file(name, missing_allowed: false)
    begin
      # First, resolve any links pointing to the generation dir itself.
      # Otherwise we'll try to resolve a path that may not exist.
      resolved_generation = readlink_system(selected_generation)

      full_path = File.join(resolved_generation, name)

      # Then resolve links to the actual artifact of the generation.
      artifact = readlink_system(File.join(resolved_generation, name))
      # Finally, return joined to the mount point.
      File.join(SYSTEM_MOUNT_POINT, artifact)
    rescue => e
      log "While searching for generation_file(#{name.inspect}):"
      log e.inspect
      if missing_allowed
        return nil
      else
        raise e
      end
    end
  end

  def run()
    init = File.join(selected_generation, "init")

    # This is the traditional way we printed the init path.
    # This is still helpful to take vertical real estate when visually looking
    # through the log.
    log("")
    log("***")
    log("")
    if will_kexec?
      log("Kexecing into #{selected_generation}")
    else
      log("Switching root to #{init}")
    end
    log("")
    log("***")
    log("")

    if will_kexec?
      if Tasks.constants.include?(:SetupGadgetMode)
        Progress.exec_with_message("Tearing down USB Gadget mode") do
          begin
            Tasks::SetupGadgetMode.instance.teardown()
          rescue => e
            $logger.fatal("Caught an error during teardown for kexec...")
            $logger.fatal(e.inspect)
          end
        end
      end

      log("About to kexec...")

      System.run(
        "kexec", "--load",
        generation_file("kernel"),
        "--initrd=#{generation_file("initrd")}",
        *[maybe_dtb()].compact(),
        "--command-line",
        [
          "init=#{readlink_system(File.join(selected_generation, "init"))}",
          # Flag used to describe we're in a kexec situation.
          # For the time being, the flag is the whole string, not the value yes to that key.
          "mobile-nixos.kexec=yes",
          "mobile-nixos.generation=#{selected_generation}",
          File.read(generation_file("kernel-params")),
        ].join(" ")
      )
      System.exec("kexec", "-e")
      raise "Failed to kexec into #{selected_generation}"
    end

    Tasks::UDev.instance.teardown()

    [
      "/proc",
      "/sys",
      "/dev",
      "/run",
    ].each do |mount_point|
      new_location = File.join(@target, mount_point)
      FileUtils.mkdir_p(new_location)
      System.run("mount", "--move", mount_point, new_location)
    end

    switch_root = System.which("switch_root")
    System.exec({}, switch_root, @target, init)
  end
end
