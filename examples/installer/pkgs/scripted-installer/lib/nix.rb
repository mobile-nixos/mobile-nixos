module Nix
  extend self

  @verbose = true;

  def nix_path()
    [
      "nixos-config=#{MOUNT_POINT}/etc/nixos/configuration.nix",
      ENV["NIX_PATH"],
    ].join(":")
  end

  def env()
    %W[
      env NIX_PATH=#{nix_path}
    ]
  end

  def silent()
    @verbose = false
  end

  def verbose()
    @verbose = true
  end

  def verbose?()
    @verbose
  end

  def show_command(cmd)
    puts " $ #{cmd.shelljoin}" if @verbose
  end

  def check_failure()
    status = $?.exitstatus
    unless status == 0
      $stderr.puts "Nix command unsuccessful (#{status})"
      exit status
    end
  end

  def nix_store_args(store: MOUNT_POINT)
    common_args = [
      # Use the running system's store as extra substituter.
      "--extra-substituters", "auto?trusted=1"
    ]

    if store then
      common_args.concat(["--store", store])
    end

    common_args
  end

  def instantiate(file = nil, expr: nil, attr: nil, instantiate: false, json: true)
    cmd = [*env, "nix-instantiate", *nix_store_args()]

    cmd << "--json" if json
    cmd << "--eval" unless instantiate
    cmd << file if file
    cmd.concat(%W[--attr #{attr}]) if attr
    cmd.concat(%W[--expr #{expr}]) if expr

    show_command(cmd)
    res = `#{cmd.shelljoin}`.strip
    check_failure()
    res = JSON.parse(res) if json
    return res
  end

  def set_profile(profile: , set: )
    cmd = [*env, "nix-env", "--profile", profile, "--set", set, *nix_store_args()]
    FileUtils.mkdir_p(File.dirname(profile))
    show_command(cmd)
    res = system(cmd.shelljoin)
    check_failure()
    return res
  end

  def realise(path)
    cmd = [*env, "nix-store", "--realise", path, *nix_store_args()]
    show_command(cmd)
    res = system(cmd.shelljoin)
    check_failure()
    return res
  end

  # Used to refer to store paths in channels without needlessly re-adding the
  # store path in the store if it's already in the store.
  def ensure_in_store(path)
    if path.match(%r{^/nix/store}) then
      return path
    end
    cmd = [*env, "nix-store", "--add", path, *nix_store_args()]
    show_command(cmd)
    res = `#{cmd.shelljoin}`.strip
    check_failure()
    return res
  end

  def build(path = nil, expr: nil, attr: [], args: {})
    raise "Nix.build can use only one of path or expr" if path and expr

    # Wrap single string attr in an array
    attr = [attr] unless attr.respond_to?(:each)

    cmd = [*env, "nix-build", "--no-out-link", *nix_store_args()]

    args.each do |name, value|
      cmd.concat(["--arg", name, value])
    end

    attr.each do |value|
      cmd.concat(["--attr", value])
    end

    cmd << "-" if expr
    cmd << path if path

    prefix =
      if expr then
        "echo #{expr.shellescape} |"
      else
        ""
      end
    
    show_command(cmd)

    res = `#{prefix}#{cmd.shelljoin}`.strip
    check_failure()
    res
  end
end
