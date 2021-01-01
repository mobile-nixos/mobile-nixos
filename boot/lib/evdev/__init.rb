module Evdev
  module FFI
    extend Fiddle::BasicTypes
    extend Fiddle::Importer

    # Indirection to pass an int as an output argument.
    Int = union ["int value"]

    dlload("libevdev.so.2")

    # https://www.freedesktop.org/software/libevdev/doc/latest/
    extern "struct libevdev * libevdev_new ()"
    extern "int libevdev_set_fd ( struct libevdev * , int )"
    extern "void libevdev_free ( struct libevdev * )"
    extern "int libevdev_has_event_type ( const struct libevdev * , unsigned int )"
    extern "const char* libevdev_get_name ( const struct libevdev * )"
    extern "int libevdev_fetch_event_value ( const struct libevdev *, unsigned int, unsigned int, int *)"
  end

  # Checks whether any of the given keys (by symbol) are held.
  # Thus, this is an OR type of operation.
  def self.keys_held(keys)
    # Temp var for holding return value while we clean up.
    ret = false

    # `evdev` works on `/dev/input/event*` nodes.
    # Check them *all*. We can't know which is a keyboard.
    Dir.glob("/dev/input/event*").each do |dev_path|

      File.open(dev_path, "r") do |dev|
        fd = dev.fileno
        evdev = FFI.libevdev_new()

        if FFI.libevdev_set_fd(evdev, fd) != 0
          $stderr.puts("warning: Could not set fd for #{dev_path}.")
        else
          # 0 is the initial value.
          buf = FFI::Int.malloc(0)

          keys.each do |key_name|
            FFI.libevdev_fetch_event_value(
              evdev,
              Linux::InputEventCodes::EV_KEY,
              Linux::InputEventCodes.const_get(key_name),
              buf
            )

            # Delay returning until after we free'd
            ret = true if buf.value == 1
          end
        end

        FFI.libevdev_free(evdev)
        return ret if ret
      end
    end

    return false
  end
end
