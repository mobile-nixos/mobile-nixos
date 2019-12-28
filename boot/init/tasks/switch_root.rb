class Tasks::SwitchRoot < SingletonTask
  # Relative to root
  SYSTEM_LINK = "/nix/var/nix/profiles/system"
  def initialize()
    add_dependency(:Target, :SwitchRoot)
    @target = "/mnt"
  end

  def find_generation()
    # The default generation
    if File.symlink?(File.join(@target, SYSTEM_LINK))
      return SYSTEM_LINK
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

    System.failure("init_not_found", "Could not find init path for stage-2", color: "FF00FF")
  end

  def run()
    # TODO: Implement generation selection choice.
    init = "#{find_generation}/init"

    # This is the traditional way we printed the init path.
    # This is still helpful to take vertical real estate when visually looking
    # through the log.
    log("")
    log("***")
    log("")
    log("Switching root to #{init}")
    log("")
    log("***")
    log("")

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
