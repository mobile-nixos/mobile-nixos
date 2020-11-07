# Note about those lengths:
# In millisecond, this much combined time (fade and progress update) will
# *also* be taken at the end to ensure animations can finish smoothly without
# being all weird.
# So adding to these values increase the boot time artificially.
# Adding less than a second overall for a cleaner UX is a good trade-off.
# More and it's not worth it.
FADE_LENGTH = 400
PROGRESS_UPDATE_LENGTH = 500

VERBOSE = !!Args.get(:verbose, false)
SOCKET = File.expand_path(Args.get(:socket, "/run/mobile-nixos-init.socket"))

# Create the UI
ui = UI.new

# Socket for status updates
puts "[splash] Listening on: ipc://#{SOCKET}"
$sub = ZMQ::Sub.new("ipc://#{SOCKET}", "")

# Initial fade-in
ui.fade_in()

# Main loop handles updating the UI, and doing some work...
LVGUI.main_loop do
  # ... work like handling the queue!

  # Empty all messages from the queue before continuing.
  loop do
    begin
      msg = JSON.parse($sub.recv(LibZMQ::DONTWAIT).to_str)
    rescue Errno::EWOULDBLOCK
      # No messages left? break out!
      break
    end

    if VERBOSE
      print "[splash:recv] "
      p msg
    end

    # We might have a special command, if we got a String rather than a Hash.
    if msg.is_a? String then
      if msg == "quit"
        ui.quit!
      else
        $stderr.puts "[splash] Unexpected command #{msg}..."
      end
    else
      # Update the UI...

      # First updating the current progress
      ui.set_progress(msg["progress"])

      # And updating the label as needed.
      if msg["label"]
        ui.set_label(msg["label"])
      else
        ui.set_label("")
      end
    end
  end
end

$stderr.puts "[splash] Broke out of the rendering loop. That's not supposed to happen."
exit(1)
