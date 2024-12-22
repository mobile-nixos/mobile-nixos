require "json"

$out = ENV["out"]
$root = ENV["mobileNixOSRoot"]

# We want `null` for `nil`s...
# We already know it's *set* at this point.
def as_nix(value)
  if value.nil?
    "null"
  else
    value.inspect
  end
end

# Filter non-mobile-nixos options.
options = JSON.parse(File.read(ENV["optionsJSON"]))
  .select do |k, v|
    v["declarations"].any? {|path| path.match(/^#{$root}/)}
  end

if options.keys.include?("nixpkgs.system")
  $stderr.puts "The options listing unexpectedly contains NixOS options."
  $stderr.puts "Bailing!"
  exit 1
end

# Write the options listing.
File.open(File.join($out, "options/index.adoc"), "w") do |file|
  file.puts <<~EOF
    = Mobile NixOS Options
    include::_support/common.inc[]
    :generated: true

    The following list only includes the options defined by Mobile NixOS.

    Refer to the link:https://search.nixos.org/options[NixOS options listing]
    for the NixOS options.

    == Options list

  EOF

  # "mobile.quirks.u-boot.initialGapSize"=>
  #{"declarations"=>
  #  [".../mobile-nixos/modules/system-types/u-boot"],
  # "default"=>true, 
  # "description"=>
  #  "Size (in bytes) to keep reserved in front of the first partition.\n",
  # "loc"=>["mobile", "quirks", "u-boot", "initialGapSize"],
  # "readOnly"=>false,
  # "type"=>"signed integer"},

  file.puts <<~EOF
    ++++
    <dl class="options-list">
  EOF
  options.keys.sort.each do |path|
    option = options[path]
    file.puts <<~EOF
    <div>
      <dt>
        <tt>
          #{path}
        </tt>
      </dt>
      <dd>
        <dl class="option-definition">
        <dt>Type:</dt>
        <dd class="option-type">#{option["type"]}</dd>
    #{
      if option.has_key?("default")
        <<~EOD
        <dt>Default:</dt>
        <dd class="option-default"><code>#{as_nix(option["default"])}</code></dd>
        EOD
      end
    }
        <dt>Description:</dt>
        <dd class="option-description">
    ++++
    #{option["description"]}
    ++++
        </dd>
      </dd>
    </div>
    EOF
  end
  file.puts <<~EOF
    </dl>
    ++++
  EOF
end
