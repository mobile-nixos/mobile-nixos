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
SKIP_FADEIN = !!Args.get(:skip_fadein, false)
SOCKET = File.expand_path(Args.get(:socket, "/run/mobile-nixos-init"))

# Create the UI
ui = UI.new

# Socket for status updates
puts "[splash] Listening on: ipc://#{SOCKET}-messages"
$messages = ZMQ::Sub.new("ipc://#{SOCKET}-messages", "")

puts "[splash] Replying on: ipc://#{SOCKET}-replies"
$replies = ZMQ::Pub.new("ipc://#{SOCKET}-replies")

# Initial fade-in
if SKIP_FADEIN
  ui.fade_in(0)
else
  ui.fade_in(FADE_LENGTH)
end

# Main loop handles updating the UI, and doing some work...
LVGUI.main_loop do
  # ... work like handling the queue!

  # Empty all messages from the queue before continuing.
  loop do
    begin
      msg = JSON.parse($messages.recv(LibZMQ::DONTWAIT).to_str)
    rescue Errno::EWOULDBLOCK
      # No messages left? break out!
      break
    end

    if VERBOSE
      print "[splash:recv] "
      p msg
    end

    # Update the UI...

    # First updating the current progress
    ui.set_progress(msg["progress"])
    ui.show_recovery_notice(msg["recovery"])

    # Update the label as needed.
    if msg["label"]
      ui.set_label(msg["label"])
    else
      ui.set_label("")
    end

    # We might have a special command; handle it.
    if msg["command"] then
      command = msg["command"]

      case command["name"]
      when "quit"
        sticky = msg["sticky"]
        ui.quit!(sticky: sticky)
      when "ask"
        ui.ask_user(placeholder: command["placeholder"], identifier: command["identifier"], cb: ->(value) do
          msg = {
            type: "reply",
            identifier: command["identifier"],
            value: value,
          }.to_json

          if VERBOSE
            print "[splash:send] "
            p msg
          end

          $replies.send(msg)
        end)
      else
        $stderr.puts "[splash] Unexpected command #{command.to_json}..."
      end
    end
  end
end

$stderr.puts "[splash] Broke out of the rendering loop. That's not supposed to happen."
exit(1)
