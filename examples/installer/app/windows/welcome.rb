module GUI
  class WelcomeWindow < BaseWindow
    include LVGUI::BaseUIElements
    include LVGUI::ButtonPalette

    def initialize()
      super()

      add_header("Welcome to the Mobile NixOS installer")

text = <<EOF

Your device booted in the Mobile NixOS installer image.

Don't worry, nothing has been done yet.

If you are not ready to install Mobile NixOS on your device at this moment, choose the "Cancel and power off" option at the bottom of this menu.

Otherwise, "Continue to the installer".

EOF
      add_text(text)

      add_button("Continue to the installer", style: :primary) do
        MainWindow.instance.present()
      end

      add_button("Cancel and power off") do
        QuitWindow.instance.present
      end
    end
  end
end
