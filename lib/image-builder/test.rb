#!/usr/bin/env nix-shell
# All dependencies `verify` will need too.
#!nix-shell --pure -p nix -p ruby -p file -i ruby

require "tmpdir"
require "open3"
require "json"
# require "fileutils"

prefix = File.join(__dir__, "tests")
NIX_PATH = "nixpkgs=channel:nixos-19.03:image-builder=#{__dir__}"

# Default directives for the test.
DEFAULT_DIRECTIVES = {
  # Default is to succeed.
  status: 0,

  # Nothing to grep for in particular.
  # (Caution! Successes are likely not to have logs!)
  grep: nil,
}

Env = {
  "NIX_PATH" => NIX_PATH,
  "TEST_MODE" => "yes",
}

tests =
  if ARGV.count > 0 then
    ARGV
  else
    # Assumes all nix files in `./tests` are tests to `nix-build`.
    Dir.glob(File.join(prefix, "**/*.nix"))
  end

$exit = 0

tests.each_with_index do |file, index|
  short_name = file.sub("#{prefix}/", "")
  print "Running test #{index+1}/#{tests.length} '#{short_name}' "

  failures = []

  # Reads the first line of the file. It may hold a json snippet
  # configuring the expected test results.
  directives = File.read(file).split("\n").first
  directives = DEFAULT_DIRECTIVES.merge(
    if directives.match(/^\s*#\s*expect:/i) then
      # Parse...
      JSON.parse(
        # Everything after the first colon as json
        directives.split(":", 2).last,
        symbolize_names: true,
    )
  else
    {}
  end
  )

  # The result symlink is in a temp directory...
  Dir.mktmpdir("image-builder-test") do |dir|
    result = File.join(dir, "result")

    # TODO : figure out how to keep stdout/stderr synced but logged separately.
    log, status = Open3.capture2e(Env, "nix-build", "--out-link", result, file)

    unless status.exitstatus == directives[:status]
      failures << "Build exited with status #{status.exitstatus} expected #{directives[:status]}."
    end

    if directives[:grep] then
      unless log.match(directives[:grep])
        failures << "Output log did not match `#{directives[:grep]}`."
      end
    end

    # Do we test further with the test scripts?
    if failures.length == 0 then
      script = file.sub(/\.nix$/, ".rb")
      if File.exists?(script) then
        log, status = Open3.capture2e(Env, File.join(__dir__, "lib/tests/verify.rb"), script, result)
      end

      unless status.exitstatus == 0
        failures << "Verification exited with status #{status.exitstatus} expected 0."
      end

      store_path = File.readlink(result)
    end

    if failures.length == 0 then
      puts "[Success] (#{store_path})"
    else
      $exit = 1
      puts "[Failed] (#{store_path || "no output"})"
      failures.each do |failure|
        puts " → #{failure}"
      end
      print "Directives: #{directives.inspect}"

      puts "\nOutput from the test:"
      puts "\n#{log}\n"
    end
  end
end

exit $exit
