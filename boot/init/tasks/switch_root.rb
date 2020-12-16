class Tasks::SwitchRoot < SingletonTask
  # Relative to root.
  DEFAULT_SYSTEM_LINK = "/nix/var/nix/profiles/system"

  # Where the system will be mounted.
  SYSTEM_MOUNT_POINT = "/mnt"

  def initialize()
    add_dependency(:Target, :SwitchRoot)
    @target = SYSTEM_MOUNT_POINT
  end

  def readlink_system(filename, strip_prefix: false)
    # Resolve the full pathname
    loop do
      prev_filename = filename

      if File.symlink?(prev_filename)
        filename = File.join(SYSTEM_MOUNT_POINT, File.readlink(prev_filename))
      end
      break if prev_filename == filename
    end
    if strip_prefix
      filename.sub(%r{^/#{SYSTEM_MOUNT_POINT}}, "")
    else
      filename
    end
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
  #  * Booting the default system link.
  #  * Find the generation store path that needs to be rehydrated.
  #
  # This is *always* a sane default to fallback on.
  def default_generation()
    # The default generation
    if File.symlink?(File.join(@target, DEFAULT_SYSTEM_LINK))
      return DEFAULT_SYSTEM_LINK
    end

    # Otherwise, we need to re-hydrate a system!
    registration = File.join(@target, "nix-path-registration")
    if File.exist?(registration)
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
    # FIXME: In the future, boot GUIs will be launched async, before this
    # task is ran.
    System.run(LOADER, "/applets/boot-selection.mrb")
    generation = File.read("/run/boot/choice")
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

  def will_kexec?()
    # Only stage-0 bootloader-flavourd init will kexec.
    return false unless STAGE == 0

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

  def generation_file(name)
    readlink_system(File.join(SYSTEM_MOUNT_POINT, selected_generation, name))
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
      System.run(
        "kexec", "--load",
        generation_file("kernel"),
        "--initrd=#{generation_file("initrd")}",
        "--command-line",
        [
          "init=#{readlink_system(File.join(SYSTEM_MOUNT_POINT, selected_generation, "init"), strip_prefix: true)}",
          File.read(generation_file("kernel-params")),
        ].join(" ")
      )
      System.exec("kexec", "-e")
      raise "Failed to kexec into #{selected_generation}"
    end

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
