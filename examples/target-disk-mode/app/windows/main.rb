module GUI
  class MainWindow < LVGUI::BaseWindow
    include LVGUI::BaseUIElements
    include LVGUI::ButtonPalette

    def run(*cmd)
      $stderr.puts " $ " + cmd.join(" ")
      system(*cmd) unless LVGL::Introspection.simulator?
    end

    def initialize()
      super()
      add_main_text("Your device should act as a USB mass storage.\n\nEject it from your system before rebooting.")

      # A reminder for simulator users
      if LVGL::Introspection.simulator?
        add_main_text("\n(Since this is running in the simulator, this actually does nothing...)\n")
      end

      # The exit options
      if LVGL::Introspection.simulator?
        add_buttons([
          ["Exit", ->() { exit 0 }],
        ])
      else
        add_buttons([
          ["Reboot", ->() { run("reboot") }],
          ["Reboot to recovery", ->() { run("reboot recovery") }],
          ["Reboot to bootloader", ->() { run("reboot bootloader") }],
          ["Power off", ->() { run("poweroff") }],
        ])
      end
    end
  end
end
