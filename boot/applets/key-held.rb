# Simple wrapper around `evtest`.
# Returns `0` when one of the listed keys is held on any input device
# Returns `10` when none of the keys are held on any input device
#
# See:
#  * https://github.com/torvalds/linux/blob/master/include/uapi/linux/input-event-codes.h

# TODO: Remove dependency on `evtest` and rather rely on direct evdev bindings.

# Mostly useless indirection.
# This better documents what we hope to achieve using this.
keys = ARGV

# `evdev` works on `/dev/input/event*` nodes.
# Check them *all*. We can't know which is a keyboard.
Dir.glob("/dev/input/event*").each do |ev|
  # `evtest` only tests one key at a time with `--query`...
  keys.each do |key|
    system("evtest", "--query", ev, "EV_KEY", key)
    # One of the keys desired is held
    if $?.exitstatus == 10
      puts "#{key} is being held"
      exit 0
    end

    # Failed for other reason
    exit $?.exitstatus unless $?.exitstatus == 0
  end
end

# Re-use 10 as "no keys held", as we're using 0 as "key held".
exit 10
