$:.unshift(Dir.pwd)
unless ARGV.length == 0
  # Replaces $0 and $PROGRAM_NAME as no one is interested in this stub.
  $0 = File.realpath(ARGV.shift)
  $PROGRAM_NAME = $0
  load $0
else
  $stderr.puts <<EOF
mruby script loader.

Usage: #{$PROGRAM_NAME} <file>

The file argument will be shifted from `ARGV`.
EOF
end
