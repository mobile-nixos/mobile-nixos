$:.unshift(Dir.pwd)
unless ARGV.length == 0
  load ARGV.shift
else
  $stderr.puts <<EOF
mruby script loader.

Usage: #{$PROGRAM_NAME} <file>

The file argument will be shifted from `ARGV`.
EOF
end
