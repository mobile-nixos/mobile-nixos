module GUI
  class BaseSystemConfigurationWindow < BaseWindow
    include LVGUI::BaseUIElements
    include LVGUI::ButtonPalette

    def initialize()
      super()

      @title = add_header("System configuration")

      @back_button = LVGUI::BackButton.new(@toolbar, self).tap do |button|
        add_to_focus_group(button)
        button.event_handler = ->(event) do
          case event
          when LVGL::EVENT::CLICKED
            @back_location.present()
          end
        end
      end
      self.back_location = nil
      self.continue_location = nil

      setup_window()

      @continue_button = add_button("Next", style: :primary) do
        if @continue_location then
          @continue_location.present()
        end
      end

      validate_step()
    end

    def present()
      super()
      @container.refresh()
    end

    def back_location=(window)
      @back_location = window
      # Hiding the button breaks the toolbar height :/
      @toolbar.set_hidden(!@back_location)
      @container.refresh()
    end

    def continue_location=(window)
      @continue_location = window
      if @continue_button then
        @continue_button.set_enabled(!!@continue_location)
        @container.refresh()
      end
    end
  end
end
