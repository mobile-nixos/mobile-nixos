# (ran using our mruby-based script-loader, so no shebang)

include Runner

if ARGV.length != 2 then
$stderr.puts <<EOF
Usage: #{$0} <mountpoint> <boot_partition>
EOF
  exit 1
end

MOUNT_POINT = File.realpath(ARGV.shift)
BOOT_PARTITION = File.realpath(ARGV.shift)

# {{{

# Launches a `nix-build` (or other).
# Default to using the store target mount point.
def nix_build(*args, command: "nix-build", store: MOUNT_POINT, verbose: nil)
  if verbose == nil then
    verbose = command != "nix-instantiate"
  end
  nix_path = [
    "nixos-config=#{MOUNT_POINT}/etc/nixos/configuration.nix",
    ENV["NIX_PATH"],
  ].join(":")

  common_args = [
    # Use the running system's store as extra substituter.
    "--extra-substituters", "auto?trusted=1"
  ]

  if store then
    common_args.concat(["--store", store])
  end

  cmd = ["env", "NIX_PATH=#{nix_path}", command, *common_args, *args]

  # This is dumb...
  # Since cpature2 can't stream the output, let's run this first...
  if verbose
    run(*cmd)
  end
  # Then only copy the result
  path, _ = capture2(*cmd, verbose: !verbose)

  # We know we want to consume paths or JSON values here.
  # Stripping eagerly is safe.
  path.strip
end

# }}}

def step_marker(text)
  puts ""
  puts ":: #{text}"
  puts ""
end

puts "================================================"
puts "= Mobile NixOS installer — automated installer ="
puts "================================================"

GENERATED_DIR = File.join(ENV["XDG_RUNTIME_DIR"], "mobile-installer")
INSTALLER_JSON = File.join(GENERATED_DIR, "installer.json")
GENERATED_NIXOS_DIR = File.join(GENERATED_DIR, "nixos")

configuration = JSON.parse(File.read(INSTALLER_JSON))


step_marker "Copying configuration..."

puts "Copying config to #{File.join(MOUNT_POINT, "/etc/nixos").inspect}"
FileUtils.mkdir_p(File.join(MOUNT_POINT, "/etc"))
FileUtils.cp_r(GENERATED_NIXOS_DIR, File.join(MOUNT_POINT, "/etc/nixos"))


step_marker "Building config"

puts "Identifying device type:"
system_type = JSON.parse(nix_build("--eval", "--json", "<nixpkgs/nixos>", "-A", "config.mobile.system.type", command: "nix-instantiate", verbose: true))
puts ""

puts "Building the NixOS system..."
toplevel = nix_build("<nixpkgs/nixos>", "-A", "config.system.build.toplevel")

puts "Building the boot image..."
case system_type
when "u-boot"
  boot_image = nix_build("<nixpkgs/nixos>", "-A", "config.mobile.outputs.u-boot.boot-partition")
  boot_image = Dir.glob(File.join(MOUNT_POINT, boot_image, "*.img")).first
when "uefi"
  boot_image = nix_build("<nixpkgs/nixos>", "-A", "config.mobile.outputs.uefi.boot-partition")
  boot_image = Dir.glob(File.join(MOUNT_POINT, boot_image, "*.img")).first
else
  raise "Cannot install for system type #{system_type}"
end

# Prevent bogus situations from happening later on if e.g. the disk image
# build infra was changed without updating the installer.
unless boot_image
  raise "`boot_image` build unexpectedly failed? (boot_image == #{boot_image.inspect})"
end


step_marker "Finalizing install"

puts "Writing boot image..."
puts "boot_image: #{boot_image}"
run(
  "dd",
  # Safe~ish value optimizing for more frequent progress updates.
  # There is no unsafe values, only slower or less frequent updates.
  "bs=8M",
  "if=#{boot_image}",
  "of=#{BOOT_PARTITION}",
  "oflag=sync,direct",
  "status=progress"
)

puts "Marking profile active..."
nix_build(
  "--profile", File.join(MOUNT_POINT, "/nix/var/nix/profiles/system"),
  "--set", toplevel,
  command: "nix-env"
)

step_marker("Installation complete!")
# Be pedantic here with the exit code as it's how we semantically tell the GUI
# that this is done.
exit(0)
