#!/usr/bin/env ruby

require "shellwords"
require "open3"

# Test harness to validate results of a `nix-build`.
# This script will `#load()` the given script.

if ARGV.length < 2 then
  abort "Usage: verify.rb <script> <result>"
end

$failures = []
$script = ARGV.shift
$result = ARGV.shift

module Helpers
  def compare_output(cmd, expected, message: nil)
    message ||= "Command `#{cmd.shelljoin}` has unexpected output:"
    expected = expected.strip
    out = `#{cmd.shelljoin}`.strip

    unless out == expected then
      $failures << "#{message}:\n\tGot:     #{out}\n\tExpected #{expected}"
    end
  end

  def sha256sum(filename, expected)
    filename = File.join($result, filename)
    compare_output(
      ["nix-hash", "--flat", "--type", "sha256", filename], expected,
      message: "File #{filename.shellescape} has unexpected hash",
    )
  end

  def file(filename, expected)
    filename = File.join($result, filename)
    compare_output(
      ["file", "--brief", filename], expected,
      message: "File #{filename.shellescape} has unexpected file type",
    )
  end
end

include Helpers

# Executes the script
load($script)

at_exit do
  if $failures.length > 0 then
    puts "Verification failed:"
    $failures.each do |failure|
      puts " → #{failure}"
    end
    exit 1
  end

  exit 0
end
