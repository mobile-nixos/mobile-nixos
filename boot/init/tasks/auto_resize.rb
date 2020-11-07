# Automatically resizes the given filesystem.
class Tasks::AutoResize < Task
  attr_reader :device

  def initialize(device, type: )
    @device = device
    @type = type
    add_dependency(:Files, @device)
  end

  def run()
    log("Resizing #{@device}...")
    if @type.match(/^ext[234]$/)
      Progress.with_message("Verifying #{@device}...") do
        # TODO: Understand the actual underlying issue with e2fsck.
        # It seems `e2fsck` succeeds, according to the output, but has a >0 exit
        # status. Running it again in those situations is a no-op, which is weird
        # to me.
        # This is why we unconditionally run it once, then twice.
        # The second will hopefully abort the boot if it fails too.
        begin
          System.run("e2fsck", "-fp", @device)
        rescue System::CommandError
          $logger.info("Re-running e2fsc...")
          System.run("e2fsck", "-fp", @device)
        end
      end
      Progress.with_message("Resizing #{@device}...") do
        System.run("resize2fs", "-f", @device)
      end
    else
      $logger.warn("Cannot resize #{@type}... filesystem left untouched.")
    end
  end
end
