module Runner
  def prettify_command(*args)
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
  # @raise [Exception] on exit status 127, commonly used for command not found.
  # @raise [Exception] on any other exit status.
  def run(*args)
    pretty_command = prettify_command(*args)
    puts(" $ #{pretty_command}")
    unless system(*args)
      raise Exception.new("Could not execute `#{pretty_command}`, status nil") if $?.nil?
      status = $?.exitstatus
      if status == 127
        raise Exception.new("Command not found... `#{pretty_command}` (#{status})")
      else
        raise Exception.new("Command failed... `#{pretty_command}` (#{status})")
      end
    end
  end

  def capture2(*args, verbose: true)
    pretty_command = prettify_command(*args)
    puts(" $ #{pretty_command}") if verbose
    Open3.capture2(*args)
  end
end
