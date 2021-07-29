module GUI
  class QuitWindow < BaseWindow
    include LVGUI::BaseUIElements
    include LVGUI::ButtonPalette

    def run(*cmd)
      $stderr.puts " $ " + cmd.join(" ")
      system(*cmd) unless LVGL::Introspection.simulator?
    end

    def initialize()
      super()

      if LVGL::Introspection.simulator?
        add_main_text("(Running in the simulator)")
        add_button("Quit", style: :primary) { exit(0) }
        return
      end

      add_button("Reboot", style: :enticing) do
        run("reboot")
      end

      add_button("Power off", style: :danger) do
        run("poweroff")
      end
    end
  end
end
