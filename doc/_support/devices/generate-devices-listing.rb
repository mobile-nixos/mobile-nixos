require "erb"
require "json"

def githubURL(device)
  "https://github.com/NixOS/mobile-nixos/tree/master/devices/#{device}"
end

NOTES_HEADER = "== Device-specific notes"

COLUMNS = [
  { key: "identifier",   name: "Identifier" },
  { key: "manufacturer", name: "Manufacturer" },
  { key: "name",         name: "Name" },
  { key: "hardware.soc", name: "SoC" },
]

$out = ENV["out"]
$devicesInfo = Dir.glob(File.join(ENV["devicesInfo"], "*")).sort.map do |filename|
  data = JSON.parse(File.read(filename))
  [data["identifier"], data]
end.to_h
$devicesDir = ENV["devicesDir"]
$systemTypesDir = ENV["systemTypesDir"]

# First, generate the devices listing.
puts ":: Generating devices/index.adoc"
File.open(File.join($out, "devices/index.adoc"), "w") do |file|
  file.puts <<~EOF
  = Devices List
  include::_support/common.inc[]
  :sitemap_index: true
  :generated: true

  The following table lists all devices Mobile NixOS available out of the
  box on the master branch.

  The inclusion in this list does not guarantee the device can boot Mobile
  NixOS, but only that it did at one point in the past. Though, efforts are
  made to ensure all of these still work.

  [.with-links%autowidth]
  |===
  #{COLUMNS.map {|col| "| #{col[:name]}" }.join("")}

  EOF

  $devicesInfo.keys.sort.each do |identifier|
    data = $devicesInfo[identifier]
    COLUMNS.each do |col|
      value = data.dig(*(col[:key].split(".")))
      if col[:key] == "identifier"
        file.puts("|<<#{identifier}.adoc#,`#{value}`>>")
      else
        file.puts("|<<#{identifier}.adoc#,#{value}>>")
      end
    end
  end

  file.puts <<~EOF
  |===

  Remember to look at the link:https://github.com/NixOS/mobile-nixos/pulls?q=is%3Aopen+is%3Apr+label%3A%22type%3A+port%22[port label]
  on the Mobile NixOS pull requests tracker, for upcoming devices.

  EOF
end

# Then generate per-device pages
$devicesInfo.values.each do |info|
  identifier = info["identifier"]
  puts ":: Generating devices/#{identifier}.adoc"
  File.open(File.join($out, "devices/#{identifier}.adoc"), "w") do |file|
    # TODO: include picture if available.

    # Generate the side-bar
    file.puts <<~EOF
    = #{info["fullName"]}
    include::_support/common.inc[]
    :generated: true

    [.device-sidebar]
    .#{info["fullName"]}
    ****
    Manufacturer:: #{info["manufacturer"]}
    Name:: #{info["name"]}
    Identifier:: #{info["identifier"]}
    System Type:: #{info["system"]["type"]}
    SoC:: #{info["hardware"]["soc"]}
    Architecture:: #{info["system"]["system"]}
    Source:: link:#{githubURL(identifier)}[Mobile NixOS repository]
    ****

    EOF

    # Generate the page contents

    systemTypeFile = File.join($systemTypesDir, info["system"]["type"], "device-notes.adoc.erb")
    if File.exists?(systemTypeFile)
      template = ERB.new(File.read(systemTypeFile))
      file.puts(template.result(binding))
    else
      file.puts("\n_(No system-specific notes available)_\n\n")
    end
    
    deviceNotesFile = File.join($devicesDir, identifier, "README.adoc")
    if File.exists?(deviceNotesFile)
      notes = File.read(deviceNotesFile).split("\n\n", 2).last.strip
      first_line = notes.lines.first.strip
      unless first_line == NOTES_HEADER
        $stderr.puts(
          "Unexpected device-specific notes header for %s.",
          "\tGot:      #{first_line.inspect}",
          "\tExpected: #{NOTES_HEADER.inspect}",
        )
        exit 1
      end
      file.puts(notes)
    else
      file.puts("\n_(No device-specific notes available)_\n\n")
    end
  end
end
