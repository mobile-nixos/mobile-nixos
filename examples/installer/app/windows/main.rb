module GUI
  class MainWindow < BaseWindow
    include LVGUI::BaseUIElements
    include LVGUI::ButtonPalette

    def network_online?()
      Hardware::Network.online?
    end

    def configuration_done?()
      SystemConfigurationStepsWindow.instance.is_valid?
    end

    def initialize()
      super()

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
        InstallationReviewWindow.instance.present
      end

      refresh_buttons()

      LVGUI::HorizontalSeparator.new(@container)

      if LVGL::Introspection.simulator?
        add_button("Fake configuration!", style: :danger) do
          FDEConfigurationWindow.instance.instance_exec do
            @passphrase_input.set_text("a passphrase")
            @passphrase_copy.set_text("a passphrase")
          end
          BasicInfoConfigurationWindow.instance.instance_exec do
            @hostname_input.set_text("example-system")
            @fullname_input.set_text("E. Xample")
            @username_input.set_text("user")
            @password_input.set_text("hunter2")
            @password_copy.set_text("hunter2")
          end
          PhoneEnvironmentConfigurationWindow.instance.instance_exec do
            @environment_selection.select(:phosh)
          end

          refresh_buttons()
        end
        add_button("Terminal Test Window") do
          TerminalTestWindow.instance.present()
        end
      end

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
