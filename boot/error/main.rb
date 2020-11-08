begin
# Get exclusive control of the framebuffer
# By design we will not restore the console at exit.
# We are assuming the target does not necessarily have a console attached to
# the framebuffer, so this program has to be enough by itself.
VTConsole.map_console(0)

# Prepare LVGL
LVGL::Hacks.init()

data = JSON.parse(File.read(ARGV.first))

$code = data["code"]
$color = data["color"]
$delay = data["delay"]
$message = data["message"]
$status = data["status"]

$color = $color.rjust(6, "0").rjust(8, "F").to_i(16)

class UI
  def initialize()
    screen
    sad_phone
    code
    message
    time_left
  end

  def screen()
    @screen = LVGL::LVContainer.new()

    # Create a new style
    style = @screen.get_style(LVGL::CONT_STYLE::MAIN).dup
    @screen.set_style(LVGL::CONT_STYLE::MAIN, style)

    style.body_main_color = $color
    style.body_grad_color = $color
  end

  def sad_phone()
    file = nil
    file = "/sad-phone.svg" if File.exist?("/sad-phone.svg")
    file = "sad-phone.svg" if File.exist?("sad-phone.svg")
    return unless file

    if @screen.get_height > @screen.get_width
      LVGL::Hacks::LVNanoSVG.resize_next_width(@screen.get_width)
    else
      LVGL::Hacks::LVNanoSVG.resize_next_height(@screen.get_height)
    end

    @sad_phone = LVGL::LVImage.new(@screen)
    @sad_phone.set_src(file)

    # Center the image
    @sad_phone.set_pos(
      @screen.get_width / 2 - @sad_phone.get_width / 2,
      @screen.get_height / 2 - @sad_phone.get_height / 2,
    )
  end

  def code()
    @code = ShadedText.new(@screen)
    @code.set_long_mode(LVGL::LABEL_LONG::BREAK)
    @code.set_align(LVGL::LABEL_ALIGN::CENTER)
    @code.set_width((@screen.get_width * 0.8).to_i)
    @code.set_text($code)
    @code.set_pos(
      @screen.get_width / 2 - @code.get_width / 2,
      (@screen.get_height * 0.05).to_i
    )
  end

  def message()
    @message = ShadedText.new(@screen)
    @message.set_long_mode(LVGL::LABEL_LONG::BREAK)
    @message.set_align(LVGL::LABEL_ALIGN::CENTER)
    @message.set_width((@screen.get_width * 0.95).to_i)
    @message.set_text($message)
    @message.set_pos(
      @screen.get_width / 2 - @message.get_width / 2,
      (@screen.get_height * 0.65).to_i
    )
  end

  def time_left()
    @time_left = ShadedText.new(@screen)
    @time_left.set_long_mode(LVGL::LABEL_LONG::BREAK)
    @time_left.set_align(LVGL::LABEL_ALIGN::CENTER)
    @time_left.set_width((@screen.get_width * 0.95).to_i)

    set_time_left($delay)

    @time_left.set_pos(
      @screen.get_width / 2 - @time_left.get_width / 2,
      (@screen.get_height - @time_left.get_height * 1.5)
    )
  end

  def set_time_left(value)
    @time_left.set_text("#{value} seconds left before crashing.")
  end
end

# Create the UI
ui = UI.new

# Run tasks once to "realize" the UI.
LVGL::Hacks::LVTask.handle_tasks

start = Time.now
LVGUI.main_loop do
  elapsed = Time.now - start
  left = $delay - elapsed

  ui.set_time_left(left.floor)

  if elapsed >= $delay
    # Ensures console is flushed entirely.
    $stdout.flush()
    $stderr.flush()

    # Exit, which will crash the kernel.
    exit $status
  end
end

# Handles outputing the error and, more importantly, flushing the output.
# When simply existing, the system might not flush the output due to the
# kernel panic.
rescue => e
  $stderr.puts("")
  $stderr.puts("Unexpected error in error handler:")
  $stderr.puts("")
  $stderr.puts(e.inspect)
  $stderr.puts("")

  $stdout.flush()
  $stderr.flush()

  sleep(1)
  exit 128
end
