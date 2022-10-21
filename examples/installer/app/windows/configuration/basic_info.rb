module GUI
  class BasicInfoConfigurationWindow < BaseSystemConfigurationWindow

    def configuration_data
      {
        info: {
          hostname: @hostname_input.get_text(),
          fullname: @fullname_input.get_text(),
          username: @username_input.get_text(),
          password: @password_input.get_text(),
        },
      }
    end

    def setup_window()
      @title.set_text("About you and your device")
      add_text(%Q{
        Let's configure some basic facts about you and your device.
      }.gsub(/^\s+/, "").strip)

      add_text("Your name\nThis is used for the user description.")
      @fullname_input = add_textarea()

      add_text("User name\nThis is the login username.")
      @username_input = add_textarea()
      @username_edited = false

      add_text("Password and confirmation")
      @password_input = add_textarea()
      @password_input.set_pwd_mode(true)
      @password_copy = add_textarea()
      @password_copy.set_pwd_mode(true)

      LVGUI::HorizontalSeparator.new(@container)

      add_text("Hostname")
      @hostname_input = add_textarea()
      @hostname_input.set_text("mobile-nixos")

      [
        @hostname_input,
        @fullname_input,
        @username_input,
        @password_input,
        @password_copy,
      ].each do |ta|
        ta.on_modified = ->(value) do
          validate_step()
        end
        ta.on_submit = ->(value) do
          validate_step()
        end
      end

      @username_input.on_modified = ->(value) do
        validate_step()
        @username_edited = true
      end

      @fullname_input.on_modified = ->(value) do
        validate_step()
        unless @username_edited then
          username = value.deburr.downcase.gsub(/ /, ".").gsub(/[^a-z0-9-.]/, "-")
          @username_input.set_text(username)
        end
      end
    end

    #
    # Validation
    #

    def is_valid?()
      valid = [
        hostname_valid?(),
        fullname_valid?(),
        username_valid?(),
        password_valid?(),
      ].all?
    end

    def hostname_valid?()
      # hostname(7)
      # Each element of the hostname must be from 1 to 63 characters long
      # and the entire hostname, including the dots, can be at most 253 characters long.  
      # Valid characters for hostnames are ASCII(7)
      # letters from a to z, the digits from 0 to 9, and the hyphen (-).
      # A hostname may not start with a hyphen.
      @hostname_input.get_text().match(/^[a-zA-Z0-9][-a-zA-Z0-9]{0,63}$/)
      # TODO validation label
      # \nMust be between 1 and 63 characters, ASCII letters, digits, hyphen invalid at the start.
    end

    def fullname_valid?()
      # https://github.com/NixOS/nixpkgs/blob/178fea1414ae708a5704490f4c49ec3320be9815/nixos/modules/config/users-groups.nix#L72
      !@fullname_input.get_text().match(/[:\n]/)
      # TODO validation label
    end

    def username_valid?()
      # https://github.com/NixOS/nixpkgs/blob/178fea1414ae708a5704490f4c49ec3320be9815/nixos/modules/config/users-groups.nix#L64
      [
        !@username_input.get_text().match(/[:\n]/),
        @username_input.get_text().length < 32,
      ].all?
      # TODO validation label
    end

    def password_valid?()
      [
        @password_input.get_text() != "",
        @password_input.get_text() == @password_copy.get_text(),
      ].all?
      # TODO validation label
    end

    def validate_step()
      # FIXME: figure out a more elegant solution :/
      return unless @continue_button

      # Ugh, let the objects update once before peeking at `get_text()`, during
      # an input event the value is not propagated yet.
      LVGL::Hacks::LVTask.once(->() do
        self.continue_location = nil

        if is_valid?()
          self.continue_location = PhoneEnvironmentConfigurationWindow.instance
        end
      end)
    end
  end
end
