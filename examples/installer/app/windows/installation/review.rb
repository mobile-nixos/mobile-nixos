module GUI
  class InstallationReviewWindow < BaseWindow
    include LVGUI::BaseUIElements
    include LVGUI::ButtonPalette

    def initialize()
      super()

      add_text(%Q{
        Before proceeding, let's review what was configured.
      }.gsub(/^ +/, "").strip)

      LVGUI::HorizontalSeparator.new(@container)

      @review_text = add_text("")

      LVGUI::HorizontalSeparator.new(@container)

      add_text(%Q{
        If you continue with the next step, the internal storage of your device
        will be erased, and formatted anew with a fresh Mobile NixOS install.

        This can lead to data loss if you have not backed up any of your
        personal data from an installed system on this device.
      }.gsub(/^ +/, "").strip)

      add_button("I understand, let's proceed", style: :enticing) do
        puts("GOOO")
      end

      add_button("Let's postpone for now...") do
        MainWindow.instance.present
      end
    end

    def refresh_state()
      @review_text.set_text([
        "Your choices:",
        Configuration.configuration_description,
      ].join("\n\n"))
    end

    def present()
      super()

      refresh_state()
    end
  end
end

