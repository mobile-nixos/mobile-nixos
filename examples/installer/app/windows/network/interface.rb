module GUI
  class NetworkInterfaceWindow < BaseWindow
    include LVGUI::BaseUIElements
    include LVGUI::ButtonPalette

    # {:interface=>"enp0s29u1u3u1", :type=>"ethernet", :state=>"unavailable", :connection=>nil}
    # {:interface=>"wlp2s0", :type=>"wifi", :state=>"connected", :connection=>"WiFi Name"}
    attr_accessor :interface

    def initialize()
      super()

      @refreshing = false

      add_header("Network interface")
      @interface_name_label = add_text("[...]")

      @choose_network_button = add_button("Choose Wireless Network") do
        NetworkWifiWindow.instance.interface = interface
        NetworkWifiWindow.instance.present()
      end
      @choose_network_button.set_hidden(true)

      add_text("Status information:")
      @status_text = MonospaceText.new(@container)

      @back_button = LVGUI::BackButton.new(@toolbar, self).tap do |button|
        add_to_focus_group(button)
        button.event_handler = ->(event) do
          case event
          when LVGL::EVENT::CLICKED
            NetworkConfigurationWindow.instance.present()
          end
        end
      end

      @container.refresh()
    end

    def present()
      super()
      refresh_interface_information()
    end

    def refresh_interface_information()
      return if @refreshing

      @interface_name_label.set_text(
        "Interface: #{interface[:interface]}"
      )
      @status_text.set_text("Refreshing...")

      @choose_network_button.set_hidden(interface[:type] != "wifi")

      @refreshing = true

      LVGL::Hacks::LVTask.once ->() do
        actually_refresh()
      end
    end

    def ipX_data(v, data)
      [
        "IPv#{v}",
        if data["IP#{v}.ADDRESS"].length == 1 then "Address:" else "Addresses:" end,
        data["IP#{v}.ADDRESS"].map do |addr|
          " - #{addr}"
        end.join("\n"),
        if data["IP#{v}.DNS"].length == 1 then "DNS server:" else "DNS servers:" end,
        data["IP#{v}.DNS"].map do |addr|
          " - #{addr}"
        end.join("\n"),
        ("Gateway: #{data["IP#{v}.GATEWAY"]}" if data["IP#{v}.GATEWAY"]),
      ]
    end

    def actually_refresh()
      data = Hardware::Network.show(interface[:interface])

      text = [
        ("Status:       #{data["GENERAL.STATE"]}" if data["GENERAL.STATE"]),
        ("Connection:   #{data["GENERAL.CONNECTION"]}" if data["GENERAL.CONNECTION"] and !data["GENERAL.CONNECTION"].match(/^\s*$/)),
        ("Mac Address:  #{data["GENERAL.HWADDR"]}" if data["GENERAL.HWADDR"]),
        "",
        (ipX_data(4, data) if data["IP4.ADDRESS"]),
        "",
        (ipX_data(6, data) if data["IP6.ADDRESS"]),
      ].compact.join("\n").gsub(/\n\n+/, "\n\n").strip

      @status_text.set_text(text)

      @refreshing = false
      @container.refresh()
    end
  end
end
