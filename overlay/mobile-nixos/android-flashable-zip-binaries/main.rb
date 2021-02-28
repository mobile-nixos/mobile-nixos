VALID_API = "3"

LOGO = <<'EOF'
 __  __     _    _ _       _  _ _      ___  ___ 
|  \/  |___| |__(_) |___  | \| (_)_ __/ _ \/ __|
| |\/| / _ \ '_ \ | / -_) | .` | \ \ / (_) \__ \
|_|  |_\___/_.__/_|_\___| |_|\_|_/_\_\\\\___/|___/

                  Flashable Zip
EOF

if ARGV[0] != VALID_API
  $stderr.puts "Installable zip API #{ARGV[1].inspect} unknown!!"
  $stderr.puts "Installable zip API must be: #{VALID_API.inspect}"
  $stderr.puts ""
  $stderr.puts "ARGV:"
  $stderr.puts ARGV.inspect
  $stderr.puts ""
  exit 1
end

# Write something quite unique, so `/tmp/recovery.log` can be cut from the
# last occurence of said string to more easily debug issues.
$stdout.puts "----- mobile-nixos-flashable-zip -----"

$zip_path = ARGV[2]

Tmp.mkdir() do |dir|
  Dir.chdir(dir) do
    10.times do
      Edify.ui_print("")
    end
    LOGO.lines.each do |line|
      Edify.ui_print(line)
    end
    Edify.ui_print("")

    # Used internally to instance_exec into...
    $_plan = FlashPlan.new()
    Installer.run_script("update-script.rb") do |script|
      # Yeah... eww...
      # `binding` isn't available yet for `eval`.
<<RUBY
  $_plan.instance_exec do
    #{script}
    execute!()
  end
RUBY
    end
  end
end

# Cleanup
Busybox._cleanup()
