require "erb"
require "json"

NOTES_HEADER = "== Device-specific notes"

COLUMNS = [
  { key: "identifier",   name: "Identifier" },
  { key: "manufacturer", name: "Manufacturer" },
  { key: "name",         name: "Name" },
  { key: "hardware.soc", name: "SoC" },
]

SUPPORT_LEVELS = {
  "supported" => {
    title: "Supported",
    description: "These devices are supported. They use mainline Linux.",
  },
  "best-effort" => {
    title: "Best effort",
    description: "These devices are almost supported, but may not be a priority, or require more work.",
  },
  "broken" => {
    title: "Broken at the moment",
    description: "Generally for a technical reason, will not work. See recent changes or issues.",
  },
  "vendor" => {
    title: "Using vendor tooling",
    description: "These devices are best-effort with kernel and different dependencies coming from vendor forks.",
  },
  "unsupported" => {
    title: "Unsupported",
    description: "These devices are not abandoned, but not supported. Lower your expectations.",
  },
  "abandoned" => {
    title: "Abandoned",
    description: "These devices are still in the repository, but are unmaintained, and abandoned.",
  },
}
SUPPORT_LEVEL_ORDER = [
  "supported",
  "best-effort",
  "broken",
  "vendor",
  "unsupported",
  "abandoned",
]

def githubURL(device)
  "https://github.com/NixOS/mobile-nixos/tree/master/devices/#{device}"
end

def hydraURL(job)
  # Yes, x86_64-linux is by design.
  # We're using the pre-built images, cross-compiled.
  # If we used the native arch, we'd be in trouble with armv7l.
  "https://hydra.nixos.org/job/mobile-nixos/unstable/#{job}"
end

def yesno(bool)
  if bool
    "yes"
  else
    "no"
  end
end

def devices_table(devices_info)
  [
    "[.with-links%autowidth]",
    "|===",
    COLUMNS.map {|col| "| #{col[:name]}" }.join(""),
    devices_info.keys.sort.map do |identifier|
      data = devices_info[identifier]
      COLUMNS.map do |col|
        value = data.dig(*(col[:key].split(".")))
        if col[:key] == "identifier"
          "|<<#{identifier}.adoc#,`#{value}`>>"
        else
          "|<<#{identifier}.adoc#,#{value}>>"
        end
      end
    end.join("\n"),
    "|===",
  ].join("\n")
end
def devices_sections(devices_info)
  grouped_devices = $devicesInfo.group_by { |_, device| device["supportLevel"] }.transform_values(&:to_h)
  missing_descriptions = grouped_devices.keys.reject {|level| SUPPORT_LEVEL_ORDER.include?(level) }
  if missing_descriptions.length > 0 then
    $stderr.puts "Missing description for support levels: #{missing_descriptions.inspect}"
    exit 1
  end
  SUPPORT_LEVEL_ORDER.map do |support_level|
    if devices = grouped_devices[support_level] then
      level = SUPPORT_LEVELS[support_level]
      [
        "== #{level[:title]}",
        "\n#{level[:description]}\n",
        devices_table(devices),
      ].join("\n")
    else
      nil
    end
  end.compact.join("\n")
end

$out = ENV["out"]
$devicesInfo = Dir.glob(File.join(ENV["devicesInfo"], "*")).sort.map do |filename|
  data = JSON.parse(File.read(filename))
  [data["identifier"], data]
end.to_h
$devicesDir = ENV["devicesDir"]

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

  Different devices have varying degree of support.

  #{devices_sections($devicesInfo)}

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
    Supports Stage-0:: #{yesno(info["quirks"]["supportsStage-0"])}
    Source:: link:#{githubURL(identifier)}[Mobile NixOS repository]

    Builds::
    #{
      info["documentation"]["hydraOutputs"].map do |pair|
        output, name = pair
        "* link:#{hydraURL(output.gsub("@device@",identifier))}[#{name}]"
      end.join("\n")
    }

    ****

    EOF

    # Generate the page contents

    template = ERB.new(File.read(info["documentation"]["systemTypeFargment"]))
    file.puts(template.result(binding))

    # Ensure the content is at least separated by an empty line.
    # Otherwise a trailing command could end-up being merged.
    file.puts("\n\n")
    
    deviceNotesFile = File.join($devicesDir, identifier, "README.adoc")
    if File.exist?(deviceNotesFile)
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
