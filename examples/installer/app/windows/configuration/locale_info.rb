module GUI
  class LocaleInfoConfigurationWindow < BaseSystemConfigurationWindow

    def self.parse_zone_tab()
      data = File.read("/etc/zoneinfo/zone.tab")
        .split(/\n+/).map(&:strip).grep(/^[^#]/)
        .map{|line| line.split(/\s+/, 4)}
        .map {|set| set[2].split("/", 2)}

      data
        .sort.group_by{ |set| set.first }
        .transform_values do |locations|
          locations.map do |list|
            list.shift
            list.join("/")
          end
        end
    end

    TZ_DATA = parse_zone_tab()

    # Copies an array into a tautological pair
    def to_pair(arr)
      arr.map {|el| [el, el]}
    end

    def configuration_data
      {
        locale: {
          timezone: selected_timezone,
        },
      }
    end

    def setup_window()
      @title.set_text("About your locale")
      add_text(%Q{
        Let's configure the device to be more useful for you.
      }.gsub(/^\s+/, "").strip)

      LVGUI::HorizontalSeparator.new(@container)

      add_text("Your timezone\nThis is used to show the correct time and date information.")
      @timezone_coarse_selection = add_select("Area", to_pair(TZ_DATA.keys)) do |new_state|
        LVGL::Hacks::LVTask.once(->() do
          select_timezone_coarse(@timezone_coarse_selection.selected)
        end)
      end
      @timezone_fine_selection = add_select("Location", []) do |new_state|
        LVGL::Hacks::LVTask.once(->() do
          select_timezone_fine(@timezone_fine_selection.selected)
        end)
      end

      # LVGUI::HorizontalSeparator.new(@container)
      # add_text("Your language")
    end

    def select_timezone_coarse(value)
      @timezone_fine_selection.set_options(to_pair(TZ_DATA[value]))
      validate_step()
    end

    def select_timezone_fine(value)
      validate_step()
    end

    #
    # Validation
    #

    def is_valid?()
      valid = [
        timezone_valid?(),
      ].all?
    end

    def timezone_valid?()

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
