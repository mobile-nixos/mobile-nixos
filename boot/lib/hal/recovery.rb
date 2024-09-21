module Hal
  module Recovery
    extend self

    KEYS = [
      # Keys used for "mobile" use-cases
      :KEY_VOLUMEUP,
      :KEY_VOLUMEDOWN,
      :KEY_UP,
      :KEY_DOWN,
      # Keys used for "computer" use-cases
      :KEY_LEFTCTRL,
      :KEY_RIGHTCTRL,
      :KEY_LEFTSHIFT,
      :KEY_RIGHTSHIFT,
      :KEY_ESC,
    ]

    def firmware_wants_recovery?()
      # "Boot as recovery" systems do not have a discrete recovery partition.
      # For those systems, when `[s_]kip_initramfs` is in the kernel cmdline, we
      # know the intent is to boot the normal system.
      # Is a "boot as recovery" device, and Is `[s_]kip_initramfs` missing?
      if Configuration["device"]["boot_as_recovery"] then
        if File.exist?("/proc/cmdline") then
          !File.read("/proc/cmdline").split(/\s+/).grep(/[s_]kip_initramfs/).any?
        end
      end
    end

    # Is this boot image a recovery image, or booted into recovery mode by the
    # device firmware?
    def is_recovery?()
      # Check in /etc/boot/config for `is_recovery`, it's assumed to be set, and
      # true, for recovery builds.
      Configuration["is_recovery"] or firmware_wants_recovery?
    end

    # Is the normal boot flow interrupted by a key input?
    def boot_interrupted?()
      Evdev.keys_held(KEYS)
    end

    def wants_recovery?
      [
        # Booted a recovery partition.
        is_recovery?,
        # Or signaling the boot selection menu should be shown.
        boot_interrupted?,
      ].any?
    end
  end
end
