module GUI
  class MainWindow < BaseWindow
    include LVGUI::BaseUIElements
    include LVGUI::ButtonPalette

    attr_accessor :configuration_done

    def network_online?()
      Hardware::Network.online?
    end

    def configuration_done?()
      configuration_done
    end

    def initialize()
      super()

      @configuration_done = false

      add_text(%Q{
        This installer is split in three steps.

           1. Network setup
           2. System configuration
           3. Installation
      }.gsub(/^ +/, "").strip)

      @current_step = add_text("")

      @network_button = add_button("Connect to a network") do
        NetworkConfigurationWindow.instance.back_location = self
        NetworkConfigurationWindow.instance.present
      end

      @configuration_button = add_button("System Configuration") do
        SystemConfigurationStepsWindow.instance.present
      end

      @installation_button = add_button("Proceed to installation") do
      end

      refresh_buttons()

      LVGUI::HorizontalSeparator.new(@container)

      add_buttons([
        ["Quit",  ->() { QuitWindow.instance.present }],
      ])
    end

    def refresh_buttons()
      @configuration_button.set_enabled(true)
      @installation_button.set_enabled(true)

      unless network_online? then
        @configuration_button.set_enabled(false)
        @installation_button.set_enabled(false)
      end

      unless configuration_done? then
        @installation_button.set_enabled(false)
      end

      # Reset buttons to the default state
      [
        @network_button,
        @configuration_button,
        @installation_button,
      ].each do |btn|
        LVGUI::Button::StyleMods.none(btn)
      end

      # Update current step button style, and tip text.
      if !network_online? then
        LVGUI::Button::StyleMods.primary(@network_button)
        @current_step.set_text("Let's first setup your network")
      elsif network_online? and !configuration_done? then
        LVGUI::Button::StyleMods.primary(@configuration_button)
        @current_step.set_text("Let's now configure your system")
      elsif network_online? and configuration_done? then
        LVGUI::Button::StyleMods.primary(@installation_button)
        @current_step.set_text("We're ready to install!")
      end
    end

    def present()
      super()
      refresh_buttons()
    end
  end
end
