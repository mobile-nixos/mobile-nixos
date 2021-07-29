class TmuxPuppeteer
  VERBOSE = false

  UID = Process.uid
  XDG_RUNTIME_DIR = ENV["XDG_RUNTIME_DIR"] or "/run/user/#{UID}"

  def _bg(*cmd)
    STDERR.puts(" $ #{cmd.shelljoin}") if VERBOSE
    `#{cmd.shelljoin} &`
  end

  def _run(*cmd)
    STDERR.puts(" $ #{cmd.shelljoin}") if VERBOSE
    ret = `#{cmd.shelljoin}`
    unless $?.success?
      STDERR.puts("Command failed...")
      STDERR.puts("-> $ #{cmd.shelljoin}")
      exit $?.exitstatus
    end
    ret
  end

  # Run a self-contained puppeteer session.
  # The tmux instance *is culled when the block exits*.
  def self.run(*args, &block)
    self.new(*args).tap do |instance|
      begin
        instance.instance_exec(&block)
      ensure
        instance.kill_server()
      end
    end
  end

  def initialize(cmd, width: 80, height: 25, socket_name: "tmux-puppeteering.sock")
    @socket_name = socket_name
    _tmux(*%W[
       new-session -A -x #{width} -y #{height} -d #{cmd} ;
       set-option remain-on-exit on
    ], runner: :_bg)
  end

  # Provides the content of the pane
  def capture_pane(*args)
    _tmux(*%w[capture-pane -p], *args)
  end

  # This transmits any non-defined functions directly to tmux.
  def method_missing(cmd, *args)
    cmd = cmd.to_s.gsub("_", "-")
    _tmux(cmd, *args)
  end

  # Send tmux commands to the proper socket.
  def _tmux(*cmd, runner: :_run)
    send(runner, *%W[tmux -f /dev/null -S #{File.join(XDG_RUNTIME_DIR, @socket_name)}], *cmd)
  end

  # Whether the (current) pane is dead or not
  def pane_dead?()
    all_variables()["pane_dead"] == "1"
  end

  # Process return code for the (current) dead pane
  def pane_dead_status()
    val = all_variables()["pane_dead_status"]
    if val
      val.to_i
    else
      nil
    end
  end

  # Returns the cursor position, and visibility
  def cursor_position()
    vars = all_variables()
    x = vars["cursor_x"].to_i
    y = vars["cursor_y"].to_i
    shown = vars["cursor_flag"] != "0"
    [x, y, shown]
  end

  # All tmux variables, in a nice easy to use Hash.
  def all_variables()
    display_message("-ap")
      .strip()
      .split(/\n/)
      .map { |s| s.split("=", 2) }
      .to_h
  end
end
