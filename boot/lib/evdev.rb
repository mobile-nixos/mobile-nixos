module Evdev
  # TODO: Remove dependency on `evtest` and rather rely on direct evdev bindings.
  def self.keys_held(keys)
    # See:
    #  * https://github.com/torvalds/linux/blob/master/include/uapi/linux/input-event-codes.h

    # `evdev` works on `/dev/input/event*` nodes.
    # Check them *all*. We can't know which is a keyboard.
    Dir.glob("/dev/input/event*").each do |ev|
      # `evtest` only tests one key at a time with `--query`...
      keys.each do |key|
        system("evtest", "--query", ev, "EV_KEY", key)
        # One of the keys desired is held
        if $?.exitstatus == 10
          puts "#{key} is being held"
          return true
        end

        # Failed for other reason
        puts "Failed to run evtest, #{$?.exitstatus}" unless $?.exitstatus == 0
      end
    end

    return false
  end
end
