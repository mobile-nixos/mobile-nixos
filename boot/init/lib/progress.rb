# Progress-reporting plumbing
module Progress
  SOCKET_PREFIX = "/run/mobile-nixos-init"

  # Starts the queue sockets.
  # This is waiting for /run/ to be available.
  # It needs to be possible to let some consumers (e.g. splash) alive from
  # stage-1 and waiting for fresh messages from stage-2.
  # A stage-2 process could ask that splash to "hand-off" to a stage-2 splash.
  def self.start()
    @progress = 0
    $logger.debug("Starting progress IPC through ZeroMQ")

    $logger.debug(" -> messages: #{SOCKET_PREFIX}")
    @messages_socket = ZMQ::Pub.new("ipc://#{SOCKET_PREFIX}-messages")

    $logger.debug("  -> replies: #{SOCKET_PREFIX}")
    @replies_socket = ZMQ::Sub.new("ipc://#{SOCKET_PREFIX}-replies", "")
  end

  # Given values (in a Hash), it will update the state with them, and send the
  # updated state to the messages queue.
  # +nil+ values are compacted out of the state.
  def self.update(values)
    @state ||= {}
    @state.merge!(values).compact!
    send_state()
  end

  # Get a specific value from the state.
  # This should be done as little as possible.
  def self.get(attr)
    @state ||= {}
    @state[attr]
  end

  # See +#get+
  def self.[](name)
    get(name)
  end

  # Send the current state over the messages socket.
  def self.send_state()
    msg = @state.to_json
    if @messages_socket
      $logger.debug("[send] #{msg}")
      @messages_socket.send(msg)
    else
      $logger.debug("[send] Socket not open yet.")
      $logger.debug("[send] Couldn't send: #{msg}")
    end
  end

  # Executes the given block, showing the message beforehand, and removing the
  # message once done.
  def self.exec_with_message(label)
    previous = get(:label)
    update({label: label})
    ret = yield
    update({label: previous})
    ret
  end

  def self.ask(placeholder, label: nil)
    identifier = "0x#{Random.rand(0xFFFFF).to_s(16)}"

    previous_label = get(:label)
    Progress.update({label: label}) if label

    update(command: {
      name: "ask",
      identifier: identifier,
      placeholder: placeholder,
    })

    value = loop do
      # Keep progress state updated for processes attaching late.
      send_state()
      value =
        each_replies do |reply|
          # A reply for the current question?
          if reply and reply["type"] == "reply" and reply["identifier"] == identifier
            break reply["value"]
          else
            nil
          end
        end
      break value if value

      # Leave some breathing room to the CPU!
      sleep(0.1)
    end

    update({label: previous_label})

    value
  end

  def self.kill()
    Tasks::Splash.instance.kill()
  end

  # Read one reply
  # If none are available, returns nil
  def self.read_reply()
    begin
      msg = @replies_socket.recv(LibZMQ::DONTWAIT).to_str
      $logger.debug("[recv] #{msg}")
      JSON.parse(msg)
    rescue Errno::EWOULDBLOCK
      # No message?
      nil
    end
  end

  # Reads replies until there are none
  def self.each_replies()
    loop do
      msg = read_reply
      break unless msg
      yield msg
    end
  end
end
