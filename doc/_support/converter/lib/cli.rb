# Some not-so-good arguments parsing
# Though, this is all done without dependencies.

# In the end, `$options` is set as a pairs of name / values
# And `$inputs` is the list of input files, parsed from
# globs.

# Currently it **only** parses `--xyz=abc` parameters.
# As this command is mostly internal, it is fine.

expand_path = ->(path) {
  File.expand_path(path)
}

OPTIONS = {
  "output_dir" => {
    desc: "Path in which to output.",
    parse: expand_path,
  },
  "root"       => {
    desc: "Root of the documentation files (default: CWD).",
    default: Dir.pwd,
    parse: expand_path,
  },
  "styles_dir" => {
    desc: "Path to a styles directory. Assumes `styles.css` is the main stylesheet.",
    parse: expand_path,
  },
}

$options = OPTIONS.map do |name, value|
  [name, value[:default]]
end.to_h

$errors = []

# For now, assume the CLI API of this tool is unstable.

# Parse parameters in two groups.
options, args = ARGV.partition do |value|
  value.match(/^--[^=]+=/)
end

$options.merge!(options.map do |opt|
  # We know the first `=` is splitting the value in two.
  # So, no need to re-regex it.
  option_name, value = opt.split("=", 2)
  # We can safely strip the leading `--`
  # And, finally, replace `-` with `_`.
  name = option_name
    .sub(/^--/, "")
    .gsub("-", "_")

  if OPTIONS.keys.include?(name) then
    option = OPTIONS[name]
    if option[:parse] then
      value = option[:parse].call(value)
    end
    [name, value]
  else
    $errors << "Option '#{option_name}' is not recognized."
    nil
  end
end.compact.to_h)

unless $options.length.positive? then
  $stderr.puts "Errors happened while parsing parameters."
  $stderr.puts $errors
    .map {|msg| " - #{msg}" }
    .join("\n")
  exit 1
end

$inputs = args.map do |patt|
  Dir.glob(patt)
end.flatten.sort
