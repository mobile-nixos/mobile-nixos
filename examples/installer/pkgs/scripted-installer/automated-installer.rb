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

CHANNELS_BUILDER = <<EOF
(import <nixpkgs> {}).callPackage (
  { lib
  , runCommand
  }:

  { channels }:

  runCommand "user-environment" {} ''
    (
    PS4=" $ "
    set -x
    mkdir -p $out
    cd $out
    ${(
      lib.concatMapStringsSep "\n" ({ name, path }: ''
      ln -sf ${lib.escapeShellArg (builtins.path { inherit path name; })} ${lib.escapeShellArg name}
    '') channels
    )}
    )
  ''
) { }
EOF

def step_marker(text)
  puts ""
  puts ":: #{text}"
  puts ""
end

puts "================================================"
puts "= Mobile NixOS installer — automated installer ="
puts "================================================"

GENERATED_DIR = File.join(ENV["XDG_RUNTIME_DIR"], "mobile-installer")
GENERATED_NIXOS_DIR = File.join(GENERATED_DIR, "nixos")

step_marker "Copying configuration..."

puts "Copying config to #{File.join(MOUNT_POINT, "/etc/nixos").inspect}"
FileUtils.mkdir_p(File.join(MOUNT_POINT, "/etc"))
FileUtils.cp_r(GENERATED_NIXOS_DIR, File.join(MOUNT_POINT, "/etc/nixos"))


step_marker "Building config"

puts "Identifying device type:"
system_type = Nix.instantiate("<nixpkgs/nixos>", attr: "config.mobile.system.type")
puts ""

puts "Building the NixOS system..."
toplevel = Nix.build("<nixpkgs/nixos>", attr: "config.system.build.toplevel")

puts "Building the boot image..."
case system_type
when "u-boot"
  boot_image = Nix.build("<nixpkgs/nixos>", attr: "config.mobile.outputs.u-boot.boot-partition")
  boot_image = Dir.glob(File.join(MOUNT_POINT, boot_image)).first
when "depthcharge"
  boot_image = Nix.build("<nixpkgs/nixos>", attr: "config.mobile.outputs.depthcharge.kpart")
  boot_image = Dir.glob(File.join(MOUNT_POINT, boot_image)).first
when "uefi"
  boot_image = Nix.build("<nixpkgs/nixos>", attr: "config.mobile.outputs.uefi.boot-partition")
  boot_image = Dir.glob(File.join(MOUNT_POINT, boot_image)).first
else
  raise "Cannot install for system type #{system_type}"
end

# Prevent bogus situations from happening later on if e.g. the disk image
# build infra was changed without updating the installer.
unless boot_image
  raise "`boot_image` build unexpectedly failed? (boot_image == #{boot_image.inspect})"
end

step_marker "Copying channels"

# We're assuming here that the NIX_PATH refs are already in the Nix store,
# since this is how the installer sets the system up. Ideally we'd do something
# like copy the NIX_PATH refs to the store only if they're not already in the
# store, but that's not trivial to do.
# Anyway channels aren't great and only used to mirror the defaults from NixOS.

defexpr = File.join(MOUNT_POINT, "/root/.nix-defexpr")
FileUtils.mkdir_p(defexpr)
File.chmod(0700, defexpr)
unless File.exist?(File.join(defexpr, "/channels")) or File.symlink?(File.join(defexpr, "/channels"))
  File.symlink("/nix/var/nix/profiles/per-user/root/channels", File.join(defexpr, "/channels"))
end

# Override work that would be done by <nixpkgs/nixos/modules/services/misc/nix-daemon.nix>
# See also `nix.nixPath` option, which uses `nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos`
# We only support `nixos-unstable` from the master branch.
# We don't publish "known good" channel releases yet for Mobile NixOS.
channels = [
  ["https://nixos.org/channels/nixos-unstable", "nixos"],
  ["https://github.com/NixOS/mobile-nixos/archive/refs/heads/master.tar.gz", "mobile-nixos"],
].map{|pair| pair.join(" ") }.join("\n")
File.write(File.join(MOUNT_POINT, "/root/.nix-channels"), channels)

# We need to synthesize a valid store path to put as the first channel symlink.
channels = <<EOF
[
  { name = "nixos"; path = #{Nix.ensure_in_store(Nix.instantiate(expr: "<nixpkgs>", json: false))}; }
  { name = "mobile-nixos"; path = #{Nix.ensure_in_store(Nix.instantiate(expr: "<mobile-nixos>", json: false))}; }
]
EOF
channels_path = Nix.build(expr: CHANNELS_BUILDER, args: {channels: channels})
puts "Activating channels..."
Nix.set_profile(profile: File.join(MOUNT_POINT, "/nix/var/nix/profiles/per-user/root/channels"), set: channels_path)

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
Nix.set_profile(profile: File.join(MOUNT_POINT, "/nix/var/nix/profiles/system"), set: toplevel)

step_marker("Installation complete!")
# Be pedantic here with the exit code as it's how we semantically tell the GUI
# that this is done.
exit(0)
