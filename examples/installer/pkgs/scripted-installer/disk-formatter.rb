
unless RUBY_ENGINE == "mruby"
require "shellwords"
end

# {{{

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
end

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

  def part(disk, number)
    if disk.match(%r{^/dev/mmcblk}) then
      [disk, "p", number].join()
    elsif disk.match(%r{^/dev/sd[a-z]}) then
      [disk, number].join()
    else
      raise "Partition numbering scheme for this disk type (for '#{disk}') not implemented."
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
      # FIXME: use proper input redirection, this leaks the passphrase in process list
      # (Which is fine enough with this implementation given it's on an ephemeral installation system)
      cmd = ["echo", "-n", passphrase.shellescape, "|"].concat(cmd)
      run(cmd.join(" "))
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
      # FIXME: use proper input redirection, this leaks the passphrase in process list
      # (Which is fine enough with this implementation given it's on an ephemeral installation system)
      cmd = ["echo", "-n", passphrase.shellescape, "|"].concat(cmd)
      run(cmd.join(" "))
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

    def self.add_partition(path, size: nil, type:, partlabel: nil)
      script = []
      if size
        # Unit is in sectors of 512 bytes
        size = (size/512.0).ceil
        script << ["size", size].join("=")
      end
      script << ["type", type].join("=")
      script << ["name", partlabel].join("=") if partlabel

      sfdisk_script(path, script.join(", "), "--append")
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

Helpers::wipefs(disk)
Helpers::GPT.format!(disk)
# Boot partition, "Linux reserved", will be flashed with boot image for now
Helpers::GPT.add_partition(disk, size: 256 * 1024 * 1024, partlabel: "boot", type: "8DA63339-0007-60C0-C436-083AC8230908")
# Reserved for future use as a BCB, if ever implemented (e.g. ask bootloader app or recovery app to do something)
Helpers::GPT.add_partition(disk, size:  1 * 1024 * 1024, partlabel: "misc",    type: "EF32A33B-A409-486C-9141-9FFB711F6266")
# Reserved for future use to "persist" data, if ever deemed useful (e.g. timezone, "last known RTC time" and such)
Helpers::GPT.add_partition(disk, size: 16 * 1024 * 1024, partlabel: "persist", type: "EBC597D0-2053-4B15-8B64-E0AAC75F4DB1")
# Rootfs partition, will be formatted and mounted as needed
Helpers::GPT.add_partition(disk, partlabel: "rootfs",  type: "0FC63DAF-8483-4772-8E79-3D69D8477DE4")

Helpers::wipefs(Helpers.part(disk, 1))
Helpers::wipefs(Helpers.part(disk, 2))
Helpers::wipefs(Helpers.part(disk, 3))
Helpers::wipefs(Helpers.part(disk, 4))

#
# Rootfs formatting
#

rootfs_partition = Helpers.part(disk, 4)

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
Helpers::Ext4.mount(rootfs_partition, "/mnt")
