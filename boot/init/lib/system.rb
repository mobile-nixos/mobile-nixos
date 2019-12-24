# "System" helpers.
module System
  class CommandError < StandardError
  end
  class CommandNotFound < CommandError
  end
  class MountError < StandardError
  end

  def self.pretty_command(*args)
    args = args.dup
    # Removes the environment hash, if present.
    args.shift if args.first.is_a?(Hash)
    pretty_command =
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
    $logger.debug(" $ #{pretty_command(*args)}")
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
    $logger.debug(" $ #{pretty_command(*args)}")
    Kernel.exec(*args)
  end

  # Discovers the location of given program name.
  def self.which(program_name)
    ENV["PATH"].split(":").each do |path|
      full = File.join(path, program_name)
      return full if File.stat(full).executable? && !File.directory?(full)
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

    run("mount", *args)
  end

  def self.failure(code, message="(No details given)", color: "000000")
    System.run("ply-image", "--clear=0x#{color}", "/sad-phone.png")
    $logger.fatal("#{code}: #{message}")
    sleep(10)
    hard_reboot
  end

  def self.hard_reboot()
    File.write("/proc/sysrq-trigger", "b\n")
  end
end
