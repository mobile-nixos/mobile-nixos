#!/usr/bin/env nix-shell
#!nix-shell -p ruby bash coreutils
#!nix-shell -i ruby

#
# Prevents:
#   .ci/nix-error-to-workflow-error.rb:20:in `split': invalid byte sequence in US-ASCII (ArgumentError)
#
# In CI situation, locale-related variables may not be as expected.
unless ENV["LC_CTYPE"] == "C.UTF-8"
  ENV["LC_CTYPE"] = "C.UTF-8"
  exec("ruby", __FILE__, *ARGV)
end

require "shellwords"
require "tempfile"

def escape_message(msg)
  # URL encoding, but only for `\n`...
  msg.gsub("\n", "%0A")
end

TITLES = {
  build_error: "Build error",
  dependency_build_error: "Dependency build error",
  evaluation_error: "Evaluation error",
  unhandled_error: "Unhandled error",
}

tmpfile = Tempfile.new("errlog")
begin
  # Ugly, but easier than streaming the logs ourselves.
  system("bash", "-c", %Q{#{ARGV.shelljoin} 2> >(tee #{tmpfile.path} >&2)})

  exit(0) if $?.success?
  stderr = tmpfile.read()
  message = stderr.split(/\n\s*error:\s*/m).last

  type =
    case message
    when /^builder for/
      :build_error
    when /^\d+\s+dependencies of derivation/
      :dependency_build_error
    else
      :evaluation_error
    end

  # For dependency failures, let's show the message of the actual build that failed.
  if type == :dependency_build_error
    # Split on the well-known marker...
    message =
      stderr
      .split(/^\s*For full logs, run /).first
      .split(/^(error: builder for '[^']+' failed with exit code \d+;)$/)
    # Then keep the split marker, and the last component, paste it back together.
    message = message[-2..-1].join("")
  end

  # https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/workflow-commands-for-github-actions#setting-an-error-message
  formatted_message = %Q{::error title="#{TITLES[type]}"::#{escape_message(message)}}

  puts ""
  puts "Message formatted for GitHub Actions:"
  puts ""
  puts formatted_message
  puts ""
  puts ""
ensure
  tmpfile.unlink
end

exit($?.exitstatus)
