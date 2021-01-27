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
    $logger.debug(" $ echo #{contents.to_json} > #{file}")
    File.write(file, contents)
  end

  def self.symlink(source, destination)
    $logger.debug(" $ ln -s #{source} #{destination}")
    File.symlink(source, destination)
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

  # Deletes files or directories indiscriminately.
  # Directories still need to be emptied beforehand.
  def self.delete(*paths)
    paths.each do |path|
      # A symlink can be directory?() true, but won't `Dir.delete()`
      # Thus the weird conditional.
      if File.symlink?(path) || !File.directory?(path)
        $logger.debug(" $ rm #{path.shellescape}")
        File.delete(path)
      else
        $logger.debug(" $ rmdir #{path.shellescape}")
        Dir.delete(path)
      end
    end
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

  # Unmounts a mount.
  def self.umount(target, *args)
    run("umount", target, *args)
  end

  def self.cmdline()
    if File.exists?("/proc/cmdline") then
      File.read("/proc/cmdline").split(/\s+/)
    else
      []
    end
  end

  def self.failure(code, title, message="(No details given)", color: "000000", delay: Configuration["boot"]["fail"]["delay"], status: 111)
    $logger.debug("-- Entering System.failure handler --")
    $logger.debug("Killing the splash applet...")
    Progress.kill()

    # First print the error we're handling.
    # The added asterisks seve to aid in finding it visually.
    5.times do
      $logger.fatal("********************************************")
    end
    $logger.fatal("")
    $logger.fatal("********************************************")
    $logger.fatal("* Fatal error in Mobile NixOS stage-1 init *")
    $logger.fatal("********************************************")
    $logger.fatal("")
    $logger.fatal("#{code}: #{title}")
    $logger.fatal("")
    $logger.fatal(message)
    $logger.fatal("")
    5.times do
      $logger.fatal("********************************************")
    end

    _flush_outputs()

    File.write("/.error.json", {
      code: code,
      title: title,
      color: color,
      delay: delay,
      message: message,
      status: status,
    }.to_json)

    # Drop down to a shell if possible and wanted.
    shell if respond_to?(:shell) && Configuration["boot"]["shellOnFail"]

    # Show the error handler applet.
    begin
      System.exec(LOADER, "/applets/boot-error.mrb", "/.error.json")
    rescue => e
      $logger.fatal("********************************************")
      $logger.fatal("* Error handler failed to start            *")
      $logger.fatal("********************************************")
      $logger.fatal(e.inspect)
      $logger.fatal("********************************************")
    end

    # If we're here, things are broken beyond belief!
    _flush_outputs()

    # As in "command not found".
    exit 127
  end

  # Flushes the outputs.
  def self._flush_outputs()
    # Flush both output
    $stdout.flush
    $stderr.flush
  end

  def self.hard_reboot()
    System.write("/proc/sysrq-trigger", "b\n")
  end
end
