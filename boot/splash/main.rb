# Get exclusive control of the framebuffer
# By design we will not restore the console at exit.
# This is done so the framebuffer keeps the image.
VTConsole.map_console(0)

# Prepare LVGL
LVGL::Hacks.init()

$file = ARGV.first

class UI
  def initialize()
    screen
    logo
  end

  def screen()
    @screen = LVGL::LVContainer.new()

    # Create a new style
    style = @screen.get_style(LVGL::CONT_STYLE::MAIN).dup
    @screen.set_style(LVGL::CONT_STYLE::MAIN, style)

    # Background for the splash, assumed black.
    style.body_main_color = 0xFF000000
    style.body_grad_color = 0xFF000000
  end

  def logo()
    return unless $file

    if @screen.get_height > @screen.get_width
      # 80% of the width
      LVGL::Hacks::LVNanoSVG.resize_next_width((@screen.get_width * 0.8).to_i)
    else
      # 15% of the height
      LVGL::Hacks::LVNanoSVG.resize_next_height((@screen.get_height * 0.15).to_i)
    end

    @logo = LVGL::LVImage.new(@screen)
    @logo.set_src($file)

    # Center the logo
    @logo.set_pos(
      @screen.get_width / 2 - @logo.get_width / 2,
      @screen.get_height / 2 - @logo.get_height / 2,
    )
  end
end

# Create the UI
ui = UI.new

# Run tasks once to "realize" the UI.
LVGL::Hacks::LVTask.handle_tasks
