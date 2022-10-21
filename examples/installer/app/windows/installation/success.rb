module GUI
  class InstallationSuccessWindow < BaseWindow
    include LVGUI::BaseUIElements
    include LVGUI::ButtonPalette

    def initialize()
      super()

      add_header("Installation successful")
      add_text([
        "The installation process completed successfully.",
        "Before booting in your fresh installation, you should power down the device, and remove the installation media.",
      ].join("\n\n"))

      LVGUI::HorizontalSeparator.new(@container)

      if LVGL::Introspection.simulator?
        add_text("(In the simulator, we quit instead.)")
        add_button("Quit", style: :enticing) do
          exit(0)
        end
      else
        add_button("Shutdown", style: :primary) do
          system("poweroff")
        end
      end
    end
  end
end
