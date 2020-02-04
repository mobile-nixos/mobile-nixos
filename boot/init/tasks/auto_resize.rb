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
      System.run("e2fsck", "-fp", @device)
      System.run("resize2fs", "-f", @device)
    else
      $logger.warn("Cannot resize #{@type}... filesystem left untouched.")
    end
  end
end
