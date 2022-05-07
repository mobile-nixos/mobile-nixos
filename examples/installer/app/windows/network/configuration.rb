module GUI
  class NetworkConfigurationWindow < BaseWindow
    include LVGUI::BaseUIElements
    include LVGUI::ButtonPalette

    def initialize()
      super()

      add_header("Network setup")
      add_text("Network interfaces")

      @refreshing = false
      @interfaces_buttons = []

      @back_button = LVGUI::BackButton.new(@toolbar, self).tap do |button|
        add_to_focus_group(button)
        button.event_handler = ->(event) do
          case event
          when LVGL::EVENT::CLICKED
            @back_location.present()
          end
        end
      end
      self.back_location = nil

      @refresh_button = add_button("#{LVGL::Symbols::REFRESH} Refresh") do
        refresh_interfaces()
      end
      @refresh_button.set_opa_scale_enable(true)

      # When coming from the toolbox, continue_location will be set to nil
      # When coming from the installer flow, continue_location will be set to the next page.
      @continue_button = add_button("Next", style: :primary) do
        @continue_location.present()
      end
      self.continue_location = nil

      @container.refresh()
    end

    def present()
      super()
      refresh_interfaces()
    end

    def back_location=(window)
      @back_location = window
      # Hiding the button breaks the toolbar height :/
      @toolbar.set_hidden(!@back_location)
      @container.refresh()
    end

    def continue_location=(window)
      @continue_location = window
      @continue_button.set_hidden(!@continue_location)
    end

    def refresh_interfaces()
      return if @refreshing

      @refreshing = true
      refresh_state()
      @interfaces_buttons.each do |btn|
        dispose_focusable_object(btn)
      end
      @interfaces_buttons = []

      LVGL::Hacks::LVTask.once ->() do
        actually_refresh()
      end
    end

    def actually_refresh()
      [Hardware::Network.wired, Hardware::Network.wifi]
        .flatten(1)
        .each do |interface|
          # {:interface=>"enp0s29u1u3u1", :type=>"ethernet", :state=>"unavailable", :connection=>nil}
          # {:interface=>"wlp2s0", :type=>"wifi", :state=>"connected", :connection=>"WiFi Name"}

          @interfaces_buttons << FlatishButton.new(@container).tap do |button|
            add_to_focus_group(button)

            button.set_label(interface[:label])
            secondary_label = [
              interface[:pretty_state]
            ]
            if interface[:connection]
              secondary_label << "(#{interface[:connection]})"
            end
            button.set_secondary_label(secondary_label.join("\n"))

            button.event_handler = ->() do
              NetworkInterfaceWindow.instance.interface = interface
              NetworkInterfaceWindow.instance.present()
            end
          end
        end

      @refreshing = false
      refresh_state()
      @container.refresh()
    end

    def refresh_state()
      # TODO: custom button should have disable/enable function
      @refresh_button.set_opa_scale(if @refreshing then 255/2 else 255 end)
    end
  end
end
