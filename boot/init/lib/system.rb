# "System" helpers.
module System
  class CommandError < StandardError
  end
  class CommandNotFound < CommandError
  end
  class MountError < StandardError
  end

  def self.prettify_command(*args)
    args = args.dup
    # Removes the environment hash, if present.
    args.shift if args.first.is_a?(Hash)
    if args.length == 1
      args.first
    else
      args.shelljoin
    end
  end

  # Runs and pretty-prints a command. Parameters and shelling-out have the same
  # meaning as with +Kernel#spawn+; one parameter is shelling-out, multiple is
  # direct +exec+.
  #
  # @param args [Array<String>] Command and parameters
  # @raise [System::CommandNotFound] on exit status 127, commonly used for command not found.
  # @raise [System::CommandError] on any other exit status.
  def self.run(*args)
    pretty_command = prettify_command(*args)
    $logger.debug(" $ #{pretty_command}")
    unless system(*args)
      raise CommandError.new("Could not execute `#{pretty_command}`, status nil") if $?.nil?
      status = $?.exitstatus
      if status == 127
        raise CommandNotFound.new("Command not found... `#{pretty_command}` (#{status})")
      else
        raise CommandError.new("Command failed... `#{pretty_command}` (#{status})")
      end
    end
  end

  # Execs and pretty-prints a command.
  def self.exec(*args)
    $logger.debug(" $ #{prettify_command(*args)}")
    Kernel.exec(*args)
  end

  # Thin wrapper over +Kernel#exec+, but with printing.
  def self.spawn(*args)
    $logger.debug(" $ #{prettify_command(*args)} &")
    Kernel.spawn(*args)
  end

  # Runs a long-running task in the background while we keep the progress
  # reporting active.
  def self.run_long_running(*args)
    pretty_command = prettify_command(*args)
    pid = System.spawn(*args)
    ret = nil

    loop do
      # Update progress
      Progress.send_state()
      # Look at the status
      break if ret = Process.wait(pid, Process::WNOHANG)
      # Don't loop too tightly
      sleep(0.1)
    end

    status = $?.exitstatus
    if status == 127
      raise CommandNotFound.new("Command not found... `#{pretty_command}` (#{status})")
    elsif !$?.success?
      raise CommandError.new("Command failed... `#{pretty_command}` (#{status})")
    end
  end

  # Discovers the location of given program name.
  def self.which(program_name)
    ENV["PATH"].split(":").each do |path|
      full = File.join(path, program_name)
      return full if File.stat(full).executable? && !File.directory?(full)
    end
  end

  def self.write(file, contents)
    $logger.debug("echo #{contents.to_json} > #{file}")
    File.write(file, contents)
  end

  # Lists all mount points.
  # This handles temporarily mounting /proc if required.
  # This will hide /proc in those instances.
  # The return format is a hash, with keys being mount point paths,
  # and values being their respective line from /proc/mounts.
  def self.mount_points()
    # This is the most horrible hack :(
    mounted_proc = false
    unless File.exists?("/proc/mounts")
      $logger.debug("Temporarily mounting /proc...")
      FileUtils.mkdir_p("/proc")
      run("mount", "-t", "proc", "proc", "/proc")
      mounted_proc = true
    end
    result = File.read("/proc/mounts").split("\n")
    run("umount", "-f", "/proc") if mounted_proc

    result = result.map do |line|
      [
        # Safe to split by space, spaces are escaped in the mount point.
        # "/tmp/test a b" ->> tmpfs /tmp/test\040a\040b tmpfs rw,relatime 0 0
        line.split(" ")[1].gsub('\040', " "),
        line
      ]
    end.to_h

    # We mounted /proc? Hide it! We've now unmounted it.
    result.delete("/proc") if mounted_proc

    result
  end

  # Mounts a filesystem of type +type+ on +dest+.
  #
  # The +source+ parameter is optional, though kept first to keep a coherent
  # order compared to the actual +mount+ command.
  #
  # @overload mount(source, dest, type:)
  #   @param source [String] (Optional) mount source, defaults to type
  #   @param dest [String] Destination path to mount to
  #   @param type [String] Type of the mount (+-t+).
  #   @param options [Array<String>] Mount options (+-o+).
  # @overload mount(dest, type:)
  #   @param dest [String] Destination path to mount to
  #   @param type [String] Type of the mount (+-t+).
  #   @param options [Array<String>] Mount options (+-o+).
  def self.mount(source, dest = nil, type: nil, options: nil)
    # Fill-in the "reversed" optional parameters.
    unless dest
      dest = source
      source = type
    end

    if source.nil? and type.nil?
      raise MountError.new("Cannot mount when missing both source and type.")
    end

    args = []
    if type
      args << "-t"
      args << type
    end
    if options
      args << "-o"
      args << options.join(",")
    end
    args << source
    args << dest

    # We may have some mountpoints already mounted from, e.g. early logging in
    # /run/log... If we're not careful we will mount over the existing mount
    # point and hide the resulting files.
    # Side-step by re-mounting to have the appropriate options.
    if mount_points.keys.include?(dest)
      $logger.debug("#{dest} already mounted, remounting.")
      run("mount", "-o", "remount", *args)
    else
      run("mount", *args)
    end
  end

  def self.sad_phone(color, code, message)
    begin
      System.run(LOADER, "/applets/boot-error.mrb", color, code, message)
    rescue CommandError => e
      $logger.fatal(e.inspect)
    end
  end

  def self.failure(code, message="(No details given)", color: "000000", delay: Configuration["boot"]["fail"]["delay"])
    Progress.kill()
    $logger.fatal("#{code}: #{message}")
    sad_phone(color, code, message)
    shell if respond_to?(:shell)
    sleep(delay)
    hard_reboot if Configuration["boot"]["fail"]["reboot"]
    exit 111
  end

  def self.hard_reboot()
    System.write("/proc/sysrq-trigger", "b\n")
  end
end
