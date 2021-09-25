module Hardware; end

# Provides facilities to get the network status.
#
# Note: all function calls block. There's not much we can do *ergonomically*
# quickly, as `mruby-thread` doesn't seem to work at the current time with the
# current setup for the LVGUI-based apps.
module Hardware::Network
  extend self

  def _nmcli(*args, linewise:)
    data, _ = Open3.capture2("nmcli", "--color", "no", "--terse", *args)
    data = data.strip().split(/\n+/)

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

  def wifi_list(interface: nil, rescan: nil)
    args = []
    if interface
      args << "ifname"
      args << interface
    end
    if rescan
      args << "--rescan"
      args << rescan
    end
    _nmcli("device", "wifi", "list", *args, linewise: true).map do |raw|
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
    wifi.map do |data|
      interface = data[:interface]
      data.merge(show(interface))
    end
      .filter do |data|
        data[:state] == "connected"
      end
      .map do |data|
        interface = data[:interface]
        networks = wifi_list(interface: interface, rescan: "no")
        network = networks.filter{|network| network[:in_use]}.first
        network.merge(data)
      end
      .sort do |a, b|
        a["GENERAL.CONNECTION"] <=> b["GENERAL.CONNECTION"]
      end
  end

  # Warning: does not actually check internet connectivity.
  def online?()
    status.any? { |info| info[:state] == "connected" }
  end

  def show(interface_identifier)
    _nmcli("device", "show", interface_identifier, linewise: false)
  end

  def connect_wifi(interface:, network:, passphrase: nil)
    interface_name = interface[:interface]
    ssid = network[:ssid]
    connection_name = "installer-#{ssid}"

    # ¯\_(ツ)_/¯
    args = ["nmcli", "connection", "del", connection_name]
    puts " $ #{args.shelljoin}"
    system(*args)

    args = [
      "nmcli",
      "connection",
      "add",
      "save", "no",
      "con-name", connection_name,
      "type", "wifi",
      "ssid", ssid,
    ]

    if passphrase then
      args.concat ([
        "wifi-sec.key-mgmt", "wpa-psk",
        "wifi-sec.psk", passphrase,
      ])
    end

    puts " $ #{args.shelljoin}"
    system(*args)
    result = $?.success?
    unless $?.success?
      yield false
      return
    end

    args = ["nmcli", "connection", "up", connection_name, "ifname", interface_name]
    puts " $ #{args.shelljoin}"
    system(*args)
    result = $?.success?

    return yield result
  end

  def debug()
    {
      status: status,
    }
  end
end
