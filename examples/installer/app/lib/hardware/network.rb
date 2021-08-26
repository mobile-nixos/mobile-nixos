module Hardware; end

# Provides facilities to get the network status.
module Hardware::Network
  extend self

  def _nmcli(*args, linewise:)
    data =
      if LVGL::Introspection.simulator?
        # Serve hardcoded testing data in simulator mode.
        # This is better than the alternative of messing with your actual network.
        case args.join(" ")
        when "device"
<<EOF
enp0s29u1u3u1:ethernet:unavailable:
wlp2s0:wifi:connected:Wireless Access Point Name
p2p-dev-wlp2s0:wifi-p2p:disconnected:
lo:loopback:unmanaged:
EOF
        when "device wifi list"
<<EOF
 :00\\:40\\:60\\:00\\:00\\:00:TELCOA316:Infra:11:540 Mbit/s:99:▂▄▆█:WPA2
 :00\\:C0\\:20\\:00\\:00\\:00:TELCOC852:Infra:6:540 Mbit/s:87:▂▄▆█:WPA2
 :00\\:20\\:60\\:00\\:00\\:00:TELCOE1389:Infra:11:260 Mbit/s:75:▂▄▆_:WPA2
 :00\\:40\\:60\\:00\\:00\\:00:TELCOA316:Infra:149:540 Mbit/s:75:▂▄▆_:WPA2
 :00\\:C0\\:B0\\:00\\:00\\:00:TELCOB4912:Infra:11:270 Mbit/s:70:▂▄▆_:WPA1 WPA2
 :00\\:C0\\:10\\:00\\:00\\:00:TELCOB13:Infra:1:130 Mbit/s:69:▂▄▆_:WPA2
 :00\\:F0\\:D0\\:00\\:00\\:00:TELCOB7170:Infra:6:270 Mbit/s:69:▂▄▆_:WPA1 WPA2
 :00\\:C0\\:20\\:00\\:00\\:00:TELCOC852:Infra:149:540 Mbit/s:69:▂▄▆_:WPA2
 :00\\:C0\\:20\\:00\\:00\\:00:TELCOC852:Infra:44:540 Mbit/s:67:▂▄▆_:WPA2
 :00\\:C0\\:20\\:00\\:00\\:00::Infra:149:540 Mbit/s:65:▂▄▆_:WPA2
 :00\\:20\\:60\\:00\\:00\\:00:TELCOE1389-5G:Infra:149:540 Mbit/s:59:▂▄▆_:WPA2
 :00\\:C0\\:B0\\:00\\:00\\:00:TELCOB9422:Infra:1:270 Mbit/s:57:▂▄▆_:WPA1 WPA2
 :00\\:40\\:60\\:00\\:00\\:00:TELCOA316:Infra:44:540 Mbit/s:55:▂▄__:WPA2
*:00\\:F0\\:C0\\:00\\:00\\:00:Wireless Access Point Name:Infra:100:270 Mbit/s:55:▂▄__:WPA2
 :00\\:C0\\:B0\\:00\\:00\\:00:TELCOB9422_media:Infra:149:270 Mbit/s:54:▂▄__:WPA1 WPA2
 :00\\:A0\\:60\\:00\\:00\\:00:TELCOA475:Infra:11:540 Mbit/s:50:▂▄__:WPA2
 :00\\:F0\\:D0\\:00\\:00\\:00:TELCOB7170_media:Infra:149:270 Mbit/s:47:▂▄__:WPA1 WPA2
 :00\\:A0\\:60\\:00\\:00\\:00:TELCOA475:Infra:149:540 Mbit/s:37:▂▄__:WPA2
 :00\\:C0\\:10\\:00\\:00\\:00:TELCOB13:Infra:157:540 Mbit/s:37:▂▄__:WPA2
 :00\\:E0\\:A0\\:00\\:00\\:00:TELCOB2304:Infra:6:195 Mbit/s:35:▂▄__:WPA1 WPA2
EOF
        when "device show wlp2s0"
<<EOF
GENERAL.DEVICE:wlp2s0
GENERAL.TYPE:wifi
GENERAL.HWADDR:00:F0:C0:00:00:00
GENERAL.MTU:1500
GENERAL.STATE:100 (connected)
GENERAL.CONNECTION:Wireless Access Point Name
GENERAL.CON-PATH:/org/freedesktop/NetworkManager/ActiveConnection/1
IP4.ADDRESS[1]:192.168.1.117/24
IP4.GATEWAY:192.168.1.1
IP4.ROUTE[1]:dst = 0.0.0.0/0, nh = 192.168.1.1, mt = 600
IP4.ROUTE[2]:dst = 192.168.1.0/24, nh = 0.0.0.0, mt = 600
IP4.DNS[1]:192.168.1.1
IP4.DOMAIN[1]:lan
IP6.ADDRESS[1]:fddd:3b6c:6a58::d53/128
IP6.ADDRESS[2]:fddd:3b6c:6a58:0:15a8:5752:8492:5857/64
IP6.ADDRESS[3]:fddd:3b6c:6a58:0:13c0:244d:a13d:422b/64
IP6.ADDRESS[4]:fe80::1a7a:5ad0:6b90:2130/64
IP6.GATEWAY:
IP6.ROUTE[1]:dst = fddd:3b6c:6a58::/48, nh = fe80::290:4cff:fe11:2001, mt = 600
IP6.ROUTE[2]:dst = fddd:3b6c:6a58::/64, nh = ::, mt = 600
IP6.ROUTE[3]:dst = fe80::/64, nh = ::, mt = 600
IP6.ROUTE[4]:dst = fddd:3b6c:6a58::d53/128, nh = ::, mt = 600
IP6.DNS[1]:fddd:3b6c:6a58::1
EOF
        else
          `nmcli --color no --terse #{args.shelljoin}`
        end
      else
        `nmcli --color no --terse #{args.shelljoin}`
      end
        .strip()
        .split(/\n+/)

    if linewise then
      data.map do |line|
        values = []
        # This may be eager and split on escaped values...
        tokens = line.split(/:/)
        #... which is why we're re-pasting them here in that case...
        tokens.each do |token|
          last_value = values[-1]
          # FIXME count backwards until we get something else than \
          #       and check whether odd or even (balanced escapes)
          if last_value and last_value[-1] == "\\" and last_value[-2] != "\\"
            values[-1] = "#{last_value[0..-2]}:#{token}"
          else
            values << token
          end
        end

        values
      end
    else
      raw = data.map do |line|
        line.split(":", 2)
      end.to_h
      data = {}
      raw.keys.sort.each do |key|
        if key.match(/\[\d+\]$/)
          new_key = key.sub(/\[\d+\]$/, "")
          data[new_key] ||= []
          data[new_key] << raw[key]
        else
          data[key] = raw[key]
        end
      end

      data
    end
  end

  def status(types: ["ethernet", "wifi"])
    _nmcli("device", linewise: true).map do |raw|
      {
        interface: raw[0],
        type: raw[1],
        state: raw[2],
        connection: raw[3],
      }
    end
      .filter do |info|
        types.include?(info[:type])
      end
      .map do |interface|
        interface[:label] = 
          case interface[:type]
          when "wifi"
            "Wi-Fi (#{interface[:interface]})"
          when "ethernet"
            "Wired (#{interface[:interface]})"
          else
            interface[:interface]
          end

        interface[:pretty_state] =
          case interface[:state]
          when "unavailable"
            "Not Connected"
          else
            interface[:state].capitalize
          end

        interface
      end
  end

  def wired()
    status(types: ["ethernet"])
  end

  def wifi()
    status(types: ["wifi"])
  end

  def wifi_list()
    _nmcli("device", "wifi", "list", linewise: true).map do |raw|
      {
        in_use: raw[0] == "*",
        bssid: raw[1],
        ssid: raw[2],
        mode: raw[3],
        chan: raw[4],
        rate: raw[5],
        signal: raw[6].to_i,
        bars: raw[7],
        security: raw[8],
      }
    end
  end

  def current_wifi()
    wifi_list.filter do |info|
      info[:in_use]
    end
  end

  # Warning: does not actually check internet connectivity.
  def online?()
    status.any? { |info| info[:state] == "connected" }
  end

  def show(interface_identifier)
    _nmcli("device", "show", interface_identifier, linewise: false)
  end

  def debug()
    {
      status: status,
    }
  end
end

=begin

puts ":: Firehose"
p Hardware::Network.debug

puts ":: Online status"
if Hardware::Network.online? then "yes" else "no" end

puts ":: Wifi list"
p Hardware::Network.wifi_list()

puts ":: Current wifi"
p Hardware::Network.current_wifi()

puts ":: wlp2s0 interface details"
p Hardware::Network.show("wlp2s0")

exit 0

=begin
=end
