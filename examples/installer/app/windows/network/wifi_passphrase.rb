module GUI
  class NetworkWifiPassphraseWindow < BaseWindow
    include LVGUI::BaseUIElements
    include LVGUI::ButtonPalette

    attr_accessor :interface

    # {
    #   :in_use=>false,
    #   :bssid=>"A0:00:00:00:00:D4",
    #   :ssid=>"Network Name",
    #   :mode=>"Infra",
    #   :chan=>"4",
    #   :rate=>"270 Mbit/s",
    #   :signal=>100,
    #   :bars=>"\xe2\x96\x82\xe2\x96\x84\xe2\x96\x86\xe2\x96\x88",
    #   :security=>"WPA2",
    # }
    attr_accessor :network

    def initialize()
      super()

      @refreshing = false

      add_header("Wireless Setup")
      @network_name_label = add_text("[...]") # Will be filled on #present

      @security_text = add_text("[...]") # Will be filled on #present
      add_text("A passphrase is necessary to continue.")

      @passphrase_input = add_textarea().tap do |ta|
        ta.on_submit = ->(value) do
          @status_text.set_text("Connecting...")
          # Push connection to next update cycle, so we get the message up.
          LVGL::Hacks::LVTask.once(->() do
            Hardware::Network.connect_wifi(interface: interface, network: network, passphrase: value) do |success|
              if success then
                @continue_button.set_enabled(true)
                @status_text.set_text("Connected successfully.")
              else
                @status_text.set_text("Failed to connect.")
              end
            end
          end, prio: LVGL::TASK_PRIO::LOWEST)
        end
      end

      @status_text = add_text("") # Will be filled on connect

      @continue_button = add_button("Continue", style: :primary) do
        MainWindow.instance.present()
      end

      @back_button = LVGUI::BackButton.new(@toolbar, self).tap do |button|
        add_to_focus_group(button)
        button.event_handler = ->(event) do
          case event
          when LVGL::EVENT::CLICKED
            NetworkWifiWindow.instance.present()
          end
        end
      end

      @container.refresh()
    end

    def present()
      super()
      refresh_network_information()
    end

    def refresh_network_information()
      return if @refreshing

      @continue_button.set_enabled(false)

      @network_name_label.set_text(
        "Network: '#{network[:ssid]}'"
      )

      @security_text.set_text(
        "This network is protected using #{network[:security]} security."
      )
    end
  end
end
