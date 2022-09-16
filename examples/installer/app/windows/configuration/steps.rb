module GUI
  class SystemConfigurationStepsWindow < BaseWindow
    include LVGUI::BaseUIElements
    include LVGUI::ButtonPalette

    STEPS = [
      [ :FDEConfigurationWindow, "Full Disk Encryption" ],
      [ :BasicInfoConfigurationWindow, "About you and your device" ],
      [ :PhoneEnvironmentConfigurationWindow, "Phone environment" ],
    ]

    def configuration_data()
      STEPS.map do |pair|
        step, name = pair
        window = GUI.const_get(step).instance
        window.configuration_data
      end
        .reduce(&:merge)
    end

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

      @buttons = {}

      STEPS.each do |pair|
        step, name = pair
        @buttons[step] = add_button(name) do
          window = GUI.const_get(step).instance
          window.present
        end
      end
    end

    def present()
      super()

      # Don't cyclically refer ton MainWindow in `#initialize`
      self.back_location = MainWindow.instance

      @container.refresh()

      # Contorted logic to:
      #  - enable only completed steps or the next step
      #  - mark the next step green

      current_found = false
      STEPS.each do |pair|
        step, name = pair
        window = GUI.const_get(step).instance
        button = @buttons[step]

        button.set_enabled(false)
        LVGUI::Button::StyleMods.none(button)

        if window.is_valid? then
          button.set_enabled(!current_found)
        else
          unless current_found then
            current_found = true
            button.set_enabled(true)
            LVGUI::Button::StyleMods.primary(button)
          end
        end
      end
    end

    def is_valid?()
      STEPS.all? do |pair|
        step, name = pair
        window = GUI.const_get(step).instance
        window.is_valid?
      end
    end

    def back_location=(window)
      @back_location = window
      # Hiding the button breaks the toolbar height :/
      @toolbar.set_hidden(!@back_location)
      @container.refresh()
    end
  end
end
