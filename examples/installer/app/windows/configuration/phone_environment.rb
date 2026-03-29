module GUI
  class PhoneEnvironmentConfigurationWindow < BaseSystemConfigurationWindow

    ENVIRONMENTS = [
      # Keep them alphabetically sorted
      [:phosh, "Phosh"],
      #[:plamo, "Plasma Mobile"],
    ]

    def configuration_data
      {
        environment: {
          phone_environment: @environment_selection.selected,
        },
      }
    end

    def setup_window()
      @title.set_text("Phone environment")
      add_text(%Q{
        Choose between a selection of phone-orientated environments.

        There may be more options available out there, but we are limiting the
        installer to well-tested options available in NixOS.

        Don't hesitate to experiment in your installed system!

        The options are presented in alphabetical order.
      }.gsub(/^\s+/, "").strip)

      @environment_selection = add_select("Environment", ENVIRONMENTS) do |new_state|
        validate_step
      end
    end

    #
    # Validation
    #

    def is_valid?()
      !!@environment_selection.selected
    end

    def validate_step()
      # FIXME: figure out a more elegant solution :/
      return unless @continue_button

      # Ugh, let the objects update once before peeking at `get_text()`, during
      # an input event the value is not propagated yet.
      LVGL::Hacks::LVTask.once(->() do
        self.continue_location = nil

        if is_valid?()
          # We're ready to install, let's go back to the main menu.
          self.continue_location = MainWindow.instance
        end
      end)
    end
  end
end
