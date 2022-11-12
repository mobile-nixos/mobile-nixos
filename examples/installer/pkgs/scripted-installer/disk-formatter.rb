
unless RUBY_ENGINE == "mruby"
require "shellwords"
end

MOUNT_POINT = "/mnt"
$depthcharge = false

# {{{

module Helpers
  include Runner
  extend self

  class Base
    class << self
      include Runner
    end

    def self.mount(source, target)
      run("mount", source, target)
    end
  end
end

# }}}

# {{{

module Helpers
  class Ext4 < Base
    def self.format(path, uuid:, label:)
      cmd = ["mkfs.ext4"]
      cmd << "-F"
      cmd << path
      cmd.concat(["-L", label])
      cmd.concat(["-U", uuid])
      run(*cmd)
    end
  end

  class LUKS < Base
    def self.format(path, uuid:, passphrase:, label: nil)
      cmd = ["cryptsetup"]
      cmd << "luksFormat"
      cmd << path
      cmd.concat(["--uuid", uuid.shellescape])
      cmd.concat(["--key-file", "-"])
      puts " $ #{prettify_command(*cmd)}"
      # FIXME: use proper input redirection, this leaks the passphrase in process list
      # (Which is fine enough with this implementation given it's on an ephemeral installation system)
      cmd = ["echo", "-n", passphrase.shellescape, "|"].concat(cmd)
      run(cmd.join(" "), verbose: false)
    end

    def self.mount(*args)
      raise "No LUKS.mount; see LUKS.open"
    end

    def self.open(path, mapper, passphrase:)
      cmd = ["cryptsetup"]
      cmd << "luksOpen"
      cmd << path
      cmd << mapper
      cmd.concat(["--key-file", "-"])
      puts " $ #{prettify_command(*cmd)}"
      # FIXME: use proper input redirection, this leaks the passphrase in process list
      # (Which is fine enough with this implementation given it's on an ephemeral installation system)
      cmd = ["echo", "-n", passphrase.shellescape, "|"].concat(cmd)
      run(cmd.join(" "), verbose: false)
    end
  end

  def self.wipefs(path)
    cmd = ["wipefs", "--all", "--force", path]
    run(*cmd)
  end
end

# }}}

# {{{
module Helpers
  class GPT < Base
    def self.sfdisk_script(disk, script, *args)
      # TODO: move to proper input redirection instead of shelling-out when possible.
      run("echo #{script.shellescape} | sfdisk --quiet #{disk.shellescape} #{args.shelljoin}")
    end

    def self.format!(path)
      sfdisk_script(path, "label: gpt")
    end

    def self.add_partition(path, size: nil, type:, partlabel: nil, uuid: nil, bootable: false)
      script = []
      if size
        # Unit is in sectors of 512 bytes
        size = (size/512.0).ceil
        script << ["size", size].join("=")
      end
      script << ["type", type].join("=")
      script << ["name", partlabel].join("=") if partlabel
      script << ["uuid", uuid].join("=") if uuid

      attributes = []
      attributes << "LegacyBIOSBootable" if bootable

      if bootable and $depthcharge
        # Marks depthcharge partition as prioritized, successful, with 5 tries left
        # https://chromium.googlesource.com/chromiumos/docs/+/HEAD/disk_format.md#Selecting-the-kernel
        bits = []
        # Priority
        bits.concat([49, 51]) # 1010 -> 10

        # Tries left
        bits.concat([52, 54]) # 0101 -> 5

        # TODO: don't pre-set the success bit, have boot-control handle this.
        # Successful
        bits.concat([56])

        attributes << bits.join(",")
      end

      script << ["attrs", attributes.join(",").inspect].join("=") unless attributes.empty?

      sfdisk_script(
          path,
          script.join(", "),
          "--append",
          "--wipe", "always",
          "--wipe-partitions", "always",
        )
    end
  end
end
# }}}

if ARGV.length != 2 then
$stderr.puts <<EOF
Usage: #{$0} <disk> <configuration.json>
EOF
  exit 1
end

puts "==========================================="
puts "= Mobile NixOS installer — disk formatter ="
puts "==========================================="
puts

disk_param = ARGV.shift
disk = File.realpath(disk_param)
configuration = JSON.parse(File.read(ARGV.shift))

puts "Working on '#{disk_param}' → '#{disk}'"

#
# Disk layout
#

# Partition count, to track the location of the last one, the rootfs.
partition_count = 5

Helpers::wipefs(disk)
Helpers::GPT.format!(disk)

# A/B support on depthcharge
if $depthcharge then
  # We're adding one more partition for A/B
  partition_count += 1
  Helpers::GPT.add_partition(disk, size: 128 * 1024 * 1024, partlabel: "boot_a", type: "FE3A2A5D-4F32-41A7-B725-ACCC3285A309", bootable: true)
  Helpers::GPT.add_partition(disk, size: 128 * 1024 * 1024, partlabel: "boot_b", type: "FE3A2A5D-4F32-41A7-B725-ACCC3285A309", bootable: false)
else
  # This assume U-Boot, without UEFI.
  # Boot partition, "Linux reserved", will be flashed with boot image for now
  Helpers::GPT.add_partition(disk, size: 256 * 1024 * 1024, partlabel: "boot", type: "8DA63339-0007-60C0-C436-083AC8230908", bootable: true)
end

# Reserved for future use as a BCB, if ever implemented (e.g. ask bootloader app or recovery app to do something)
Helpers::GPT.add_partition(disk, size:  1 * 1024 * 1024, partlabel: "misc",    type: "EF32A33B-A409-486C-9141-9FFB711F6266")
# Reserved for future use to "persist" data, if ever deemed useful (e.g. timezone, "last known RTC time" and such)
Helpers::GPT.add_partition(disk, size: 16 * 1024 * 1024, partlabel: "persist", type: "EBC597D0-2053-4B15-8B64-E0AAC75F4DB1")
# Reserved for `pstore-blk`
Helpers::GPT.add_partition(disk, size: 15 * 1024 * 1024, partlabel: "pstore",  type: "989411FC-DFDF-40DE-9C6C-977218B794E7", uuid: "989411FC-DFDF-40DE-9C6C-977218B794E7")
# Rootfs partition, will be formatted and mounted as needed
Helpers::GPT.add_partition(disk, partlabel: "rootfs",  type: "0FC63DAF-8483-4772-8E79-3D69D8477DE4")

puts "Waiting for target partitions to show up..."

# Wait up to a minute
(1..600).each do |i|
  print "."
  # Assumes they're all present if the last is present
  break if File.exists?(Helpers::Part.part(disk, partition_count))
  sleep(0.1)
end
# two dots such that if it's instant we get a proper length ellipsis!
print ".. present!\n"

#
# Rootfs formatting
#

# The rootfs is the last partition
rootfs_partition = Helpers::Part.part(disk, partition_count)

if configuration["fde"]["enable"] then
  Helpers::LUKS.format(
    rootfs_partition,
    uuid: configuration["filesystems"]["luks"]["uuid"],
    passphrase: configuration["fde"]["passphrase"]
  )
  mapper_name = "installer-rootfs"
  # We don't need to care about the mapper name here; we are not
  # using the NixOS config generator.
  Helpers::LUKS.open(
    rootfs_partition,
    mapper_name,
    passphrase: configuration["fde"]["passphrase"]
  )
  mapper_name = File.join("/dev/mapper", mapper_name)
  puts ":: NOTE: rootfs block device changed from '#{rootfs_partition}' to '#{mapper_name}'"
  rootfs_partition = mapper_name
end

Helpers::Ext4.format(
  rootfs_partition,
  uuid: configuration["filesystems"]["rootfs"]["uuid"],
  label: configuration["filesystems"]["rootfs"]["label"]
)
Dir.mkdir(MOUNT_POINT) unless Dir.exist?(MOUNT_POINT)
Helpers::Ext4.mount(rootfs_partition, MOUNT_POINT)
