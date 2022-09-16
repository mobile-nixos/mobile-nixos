module GUI
  class FDEConfigurationWindow < BaseSystemConfigurationWindow

    def setup_window()
      @title.set_text("Full Disk Encryption")
      add_text(%Q{
        Your Mobile NixOS system can be configured with Full Disk Encryption.

        It will require entering a passphrase during boot.

        The rootfs, including the home directory, will be encrypted using LUKS.
      }.gsub(/^\s+/, "").strip)

      @enable_fde = add_switch(
        "Use Full Disk Encryption",
        description: "[...]",
        initial: true,
      ) do |new_state|
        toggle_passphrase(new_state)
      end

      @passphrase_input_label = add_text("Passphrase for the disk")
      @passphrase_input = add_textarea()
      #@passphrase_input.set_placeholder_text("Passphrase")

      @passphrase_copy_label = add_text("Repeat passphrase")
      @passphrase_copy = add_textarea()
      #@passphrase_copy.set_placeholder_text("Repeat passphrase")

      @passphrase_state = add_text("")

      [@passphrase_input, @passphrase_copy].each do |ta|
        ta.set_pwd_mode(true)
        ta.on_click = ->() do
          validate_step()
        end
        ta.on_submit = ->(value) do
          validate_step()
        end
        ta.on_modified = ->(value) do
          validate_step()
        end
      end

      toggle_passphrase(true)
    end

    def toggle_passphrase(new_state)
        if new_state then
          @enable_fde.set_description("The rootfs will be encrypted")
        else
          @enable_fde.set_description("The rootfs will not be encrypted")
        end

        [
          @passphrase_state,
          @passphrase_input_label,
          @passphrase_input,
          @passphrase_copy_label,
          @passphrase_copy,
        ].each do |el|
          el.set_hidden(!new_state)
        end

        validate_step()
    end

    #
    # Validation
    #

    def is_valid?()
      [
        passphrase_valid?()
      ].all?
    end

    def passphrase_valid?()
      # No need to do passphrase validation when FDE is not enabled.
      unless @enable_fde.get_state == true
        return true
      end

      # Otherwise check the passphrase are equivalent and non-empty.
      if @passphrase_input.get_text() == @passphrase_copy.get_text() and @passphrase_input.get_text() != "" then
        @passphrase_state.set_text("The passphrases match, you're good to go!")
      elsif @passphrase_input.get_text() != "" then
        @passphrase_state.set_text("The passphrases don't match")
        return false
      else
        @passphrase_state.set_text("Please enter a passphrase")
        return false
      end

      return true
    end

    def validate_step()
      # FIXME: figure out a more elegant solution :/
      return unless @continue_button

      # Ugh, let the objects update once before peeking at `get_text()`, during
      # an input event the value is not propagated yet.
      LVGL::Hacks::LVTask.once(->() do
        self.continue_location = nil

        if is_valid?()
          self.continue_location = BasicInfoConfigurationWindow.instance
        end
      end)
    end
  end
end
