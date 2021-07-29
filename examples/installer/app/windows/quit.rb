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

      @back_button = LVGUI::BackButton.new(@toolbar, self).tap do |button|
        add_to_focus_group(button)
        button.event_handler = ->(event) do
          case event
          when LVGL::EVENT::CLICKED
            @back_location.present()
          end
        end
      end
      @container.refresh

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

    def back_location=(window)
      @back_location = window
    end
  end
end
