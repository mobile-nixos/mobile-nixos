def pp(x)
  puts(x.inspect)
end

def prepare_environment()
  rules = File.read("/etc/udev/rules.d/00-env.rules").strip.split("\n")
  rules.each do |r|
    name, value = r.split("=", 2)
    name = name.match(/^ENV{(.*)}$/)[1]
    value = value.sub(/^"/, "").sub(/"$/, "")
    ENV[name] = value
  end
end

def prepare_mounts()
  # FIXME : porcelain around mkdir and mount
  system("mkdir", "-p", "/proc", "/sys", "/dev")
  system("mount", "-t", "devtmpfs", "devtmpfs", "/dev")
  system("mount", "-t", "proc", "proc", "/proc")
  system("mount", "-t", "sysfs", "sysfs", "/sys")
end

def prepare_framebuffer()
  # [ -e "/sys/class/graphics/fb0/modes" ] || return
  # [ -z "$(cat /sys/class/graphics/fb0/mode)" ] || return

  # _mode="$(cat /sys/class/graphics/fb0/modes)"
  # echo "Setting framebuffer mode to: $_mode"
  # echo "$_mode" > /sys/class/graphics/fb0/mode
  mode = File.read("/sys/class/graphics/fb0/modes")
  puts "Setting framebuffer mode to: #{mode}"
  File.open("/sys/class/graphics/fb0/mode", "w") do |f|
    f.write(mode)
  end
end

prepare_environment

puts "----"
puts "Environment:"
pp ENV
puts "----"

prepare_mounts

system("ls", "-l", "/sys")
system("ls", "-l", "/sys/class")
system("ls", "-l", "/sys/class/graphics")
system("ls", "-l", "/sys/class/graphics/fb0")
system("ls", "-l", "/sys/class/graphics/fb0/modes")
prepare_framebuffer

system("ply-image", "/splash.stage-0.png")

while true do
  puts("Hello from this init!")
  sleep(1)
end
