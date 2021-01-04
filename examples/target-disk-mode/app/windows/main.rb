module GUI
  class MainWindow < LVGUI::BaseWindow
    include LVGUI::ButtonPalette

    def run(*cmd)
      $stderr.puts " $ " + cmd.join(" ")
      system(*cmd) unless LVGL::Introspection.simulator?
    end

    def initialize()
      super()

      LVGL::LVLabel.new(@container).tap do |label|
        label.set_long_mode(LVGL::LABEL_LONG::BREAK)
        label.set_text("Your device should act as a USB mass storage.\n\nEject it from your system before rebooting.")
        label.set_align(LVGL::LABEL_ALIGN::CENTER)
        label.set_width(@container.get_width_fit)
      end

      # TODO: At some point, allow selecting the storage device to present.
      # Though, this will need better coordination with a "gadget mode tool" system
      # that will be able to re-do the USB gadget work.
      add_buttons([
        ["Reboot", ->() { run("reboot") }],
        ["Reboot to recovery", ->() { run("reboot recovery") }],
        ["Reboot to bootloader", ->() { run("reboot bootloader") }],
        ["Power off", ->() { run("poweroff") }],
      ])
    end
  end
end
