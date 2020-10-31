# Progress-reporting plumbing
module Progress
  SOCKET = "/run/mobile-nixos-init"

  def self.start()
    @progress = 0
    $logger.debug("Starting progress IPC through ZeroMQ")

    $logger.debug(" -> messages: #{SOCKET}")
    @messages = ZMQ::Pub.new("ipc://#{SOCKET}-messages")

    $logger.debug("  -> replies: #{SOCKET}")
    @replies = ZMQ::Pub.new("ipc://#{SOCKET}-replies")
  end

  # Prefer not sending messages directly, rather use the helpers.
  def self.publish(msg)
    msg = msg.to_json
    if @messages
      $logger.debug("[send] #{msg}")
      @messages.send(msg)
    else
      $logger.debug("[send] Couldn't send #{msg}")
    end
  end

  # Sets the progress to a specific amount
  def self.set(amount)
    @progress = amount

    publish({
      progress: @progress,
    })
  end

  # Executes the given block, showing the message beforehand, and removing the
  # message once done.
  def self.with_message(msg)
    publish({
      progress: @progress,
      label: msg,
    })
    yield
    publish({
      progress: @progress,
    })
  end
end
