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
  boot_image = Dir.glob(File.join(MOUNT_POINT, boot_image, "*.img")).first
when "uefi"
  boot_image = Nix.build("<nixpkgs/nixos>", attr: "config.mobile.outputs.uefi.boot-partition")
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
Nix.set_profile(profile: File.join(MOUNT_POINT, "/nix/var/nix/profiles/system"), set: toplevel)

step_marker("Installation complete!")
# Be pedantic here with the exit code as it's how we semantically tell the GUI
# that this is done.
exit(0)
