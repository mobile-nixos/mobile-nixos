module Partitions
  BLOCK_DEVICE_LOCATIONS = [
    "/dev",
    "/dev/block",
  ]
  SUFFIX = Android.get_prop("ro.boot.slot_suffix", "")
  extend self

  # Returns the path to the device node for the partition.
  def by_partname(name)
    candidate = Dir.glob("/sys/class/block/*/uevent").map do |path|
      File.read(path)
    end.select do |uevent|
      uevent.match(/^PARTNAME=#{name}(#{SUFFIX})?$/)
    end

    # Found nothing?
    return [nil, "Partition named #{name.inspect} not found."] if candidate.length == 0

    if candidate.length > 1 then
      return [nil, "#{candidate.length} possible block devices found."]
    end

    candidate = candidate.first
    values = candidate.split(/\n+/).map do |line|
      line.split("=", 2)
    end.to_h

    device = BLOCK_DEVICE_LOCATIONS.map do |root|
      File.join(root, values["DEVNAME"])
    end.select do |path|
      File.exist?(path)
    end.first

    if device
      [device, nil]
    else
      [nil, "Partition found as #{values["DEVNAME"].inspect}, but not found in any of #{BLOCK_DEVICE_LOCATIONS.inspect}."]
    end
  end
end
