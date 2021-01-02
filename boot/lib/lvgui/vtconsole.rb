module VTConsole
  # Allows unmapping the "vtcon" console from the frame buffer
  # This will ensure it doesn't trample on our lvgui.
  def self.map_console(value)
    # BAD HACK!
    # This always tries to map/unmap the console from the framebuffer
    # even when not using the framebuffer output! (Simulator)
    # TODO: better introspection to allow the app to know it is running in a
    # simulated environment.
    begin
      # We don't know which one(s) are running on the frame buffer.
      Dir.glob("/sys/class/vtconsole/vtcon*").each do |dir|
        # So we check...
        if File.read(File.join(dir, "name")).strip.match(/frame buffer/)
          # And only write to those.
          File.open(File.join(dir, "bind"), "w") do |file|
            file.write(value.to_s)
          end
        end
      end
    rescue
    end
  end
end
