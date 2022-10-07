module Helpers
  module Part
    extend self

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
end
