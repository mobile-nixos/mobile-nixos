# Get exclusive control of the framebuffer
# By design we will not restore the console at exit.
# We are assuming the target does not necessarily have a console attached to
# the framebuffer, so this program has to be enough by itself.
VTConsole.map_console(0)

# Prepare LVGL
LVGL::Hacks.init()

$color = ARGV.shift
$code = ARGV.shift
$message = ARGV.shift

$color = $color.rjust(6, "0").rjust(8, "F").to_i(16)

# This only works as long as the elements are not in a layout.
class ShadedText
  def initialize(*args)
    @secondary = LVGL::LVLabel.new(*args)
    style = @secondary.get_style(LVGL::LABEL_STYLE::MAIN).dup
    @secondary.set_style(LVGL::LABEL_STYLE::MAIN, style)
    style.text_color = 0xFF000000

    @main = LVGL::LVLabel.new(*args)
    style = @main.get_style(LVGL::LABEL_STYLE::MAIN).dup
    @main.set_style(LVGL::LABEL_STYLE::MAIN, style)
    style.text_color = 0xFFFFFFFF

    # Ensures the position is reset at least once.
    set_pos(0, 0)
  end

  def method_missing(*args)
    @main.send(*(args.dup))
    @secondary.send(*(args.dup))
  end

  def set_pos(x, y)
    @main.set_pos(x, y)
    @secondary.set_pos(x+2, y+2)
  end
end

class UI
  def initialize()
    screen
    sad_phone
    code
    message
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
    return unless file

    if @screen.get_height > @screen.get_width
      LVGL::LVNanoSVG.resize_next_width(@screen.get_width)
    else
      LVGL::LVNanoSVG.resize_next_height(@screen.get_height)
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
end

# Create the UI
ui = UI.new

# Run tasks once to "realize" the UI.
LVGL::Hacks::LVTask.handle_tasks
