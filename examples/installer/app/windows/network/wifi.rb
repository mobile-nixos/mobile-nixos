module GUI
  class NetworkWifiWindow < BaseWindow
    include LVGUI::BaseUIElements
    include LVGUI::ButtonPalette

    attr_accessor :interface

    def initialize()
      super()

      add_header("Wireless Setup")
      add_text("Select a wireless network to connect to")

      @refreshing = false
      @network_buttons = []

      @back_button = LVGUI::BackButton.new(@toolbar, self).tap do |button|
        add_to_focus_group(button)
        button.event_handler = ->(event) do
          case event
          when LVGL::EVENT::CLICKED
            NetworkInterfaceWindow.instance.present()
          end
        end
      end

      @refresh_button = add_button("#{LVGL::Symbols::REFRESH} Refresh") do
        refresh_access_points()
      end
      @refresh_button.set_opa_scale_enable(true)

      @container.refresh()
    end

    def present()
      super()
      refresh_access_points()
    end

    def refresh_access_points()
      return if @refreshing

      @refreshing = true
      refresh_state()
      @network_buttons.each do |btn|
        dispose_focusable_object(btn)
      end
      @network_buttons = []

      LVGL::Hacks::LVTask.once ->() do
        actually_refresh()
      end
    end

    def actually_refresh()
      current, other =
        Hardware::Network.wifi_list(interface: interface[:interface], rescan: "yes").partition do |net|
          net[:in_use]
        end
      networks = [current, other].flatten(1)

      networks.each do |net|
        next if net[:ssid] == ""
        label = []
        if net[:in_use]
          label << "\uf192"
        else
          label << "\uf10c"
        end
        label << net[:ssid]
        label << "(#{net[:signal]}%)"
        if net[:security] != ""
          label << "\uf023"
        end
        @network_buttons << add_button(label.join(" ")) do
          NetworkWifiPassphraseWindow.instance.network = net
          NetworkWifiPassphraseWindow.instance.present()
        end
      end

      @refreshing = false
      refresh_state()
      @container.refresh()
    end

    def refresh_state()
      # FIXME: custom button should have disable/enable function
      @refresh_button.set_opa_scale(if @refreshing then 255/2 else 255 end)
    end
  end
end
