# Refreshing at 120 times per second *really* helps with the drag operations
# responsiveness. At 60 it feels a bit sluggish.
# This likely comes from the naïve implementation that we are not refreshing at
# 60 times per seconds, but rather, refresh and wait 1/60th of a second. This
# makes the refresh rate a tad slower.
# Boosting to 120 doesn't seem to have ill effects. It's simply refreshed more.
REFRESH_RATE = 120

# UI constants
NIXOS_LIGHT_HUE = 205
NIXOS_DARK_HUE  = 220

# Define the arguments
Args.define({
  resolution: nil,
})

# This is used by the "simulator".
if Args.get(:resolution)
  pair = Args.get(:resolution).split("x")
  unless pair.length == 2
    $stderr.puts "--resolution <width>x<height>"
    exit 2
  end
  LVGL::Hacks.monitor_width = pair.first.to_i
  LVGL::Hacks.monitor_height = pair.last.to_i
else
  LVGL::Hacks.monitor_width = 720
  LVGL::Hacks.monitor_height = 1280
end

# Get exclusive control of the framebuffer
VTConsole.map_console(0)

# Prepare LVGL
LVGL::Hacks.init()
# And switch to the desired theme
LVGL::Hacks.theme_night(NIXOS_LIGHT_HUE)

# Unsightly hacks {{{

# Dummy container to get its style.
LVGL::LVContainer.new.tap do |container|
  style = container.get_style(LVGL::CONT_STYLE::MAIN)
  # TODO: Determine what this "constant" is
  # This ends up being different depending on the generations, probably the DPI
  # This is used to "fix" some layouting issues where filling fails.
  # 1280 == 10
  # 1920 == 15
  $fix_padding = style.body_padding_inner
end

# }}}

# Wraps an LVGL widget.
class Widget
  def initialize(widget)
    @widget = widget
  end
  def method_missing(*args)
    @widget.send(*args)
  end
end

# Implements a clock as a wrapped LVLabel.
class Clock < Widget
  def initialize(parent)
    super(LVGL::LVLabel.new(parent))
    set_align(LVGL::LABEL_ALIGN::LEFT)
    set_long_mode(LVGL::LABEL_LONG::CROP)

    # Update the text once
    update_clock

    # Then register a task to update regularly.
    @task = LVGL::Hacks::LVTask.create_task(250, LVGL::TASK_PRIO::MID, ->() do
      update_clock
    end)
  end

  def update_clock()
    set_text(Time.now.strftime("%T"))
  end
end

# Big ball of code to build the UI.
# Should be refactored in discrete "Widget" things.
class UI
  attr_reader :container
  def initialize()
    screen
    header
    logo
    container
  end

  def screen()
    @screen = LVGL::LVContainer.new()
    #@screen.set_fit2(LVGL::FIT::FILL, LVGL::FIT::TIGHT)
    @screen.set_layout(LVGL::LAYOUT::COL_M)

    style = @screen.get_style(LVGL::CONT_STYLE::MAIN).dup
    @screen.set_style(LVGL::CONT_STYLE::MAIN, style)
    style.body_padding_top = 0
    style.body_padding_left = 0
    style.body_padding_right = 0
    style.body_padding_bottom = 0
  end

  def container()
    @tabview = LVGL::LVTabview.new(@screen)
    @tabview.set_sliding(false)
    @tabview.set_anim_time(0)

    tab_style = @tabview.get_style(LVGL::TABVIEW_STYLE::BG).dup
    @tabview.set_style(LVGL::TABVIEW_STYLE::BG, tab_style)
    #tab_style.body_main_color = 0xFF0000FF
    #tab_style.body_grad_color = 0xFF0000FF

    @tabs = {}
    @tabs[:default] = @tabview.add_tab("Boot options")
    @tabs[:generations] = @tabview.add_tab("Generations")

    @tabs.each do |id, tab|
      page = LVGL::LVPage.new(tab)

      # It seems tabview auto-height is broken :/
      # This assumes there is nothing *after* the tabview.
      @tabview.set_height(
        @screen.get_height - @tabview.get_y
      )

      # "tabview" filling is seemingly broken...
      page.set_width(
        tab.get_width_fit - page.get_x*2
      )
      page.set_height(
        tab.get_height_fit - page.get_y -
        tab.get_style(LVGL::CONT_STYLE::MAIN).body_padding_inner - $fix_padding
      )
      style = LVGL::LVStyle::STYLE_TRANSP.dup
      style.body_padding_top = 0
      style.body_padding_left = 0
      style.body_padding_right = 0
      style.body_padding_bottom = 0
      #style.body_main_color = 0xFFFF0000
      #style.body_grad_color = 0xFFFF0000
      page.set_style(LVGL::PAGE_STYLE::BG, style)
      page.set_style(LVGL::PAGE_STYLE::SCRL, style)
      page.set_scrl_layout(LVGL::LAYOUT::COL_M)

      instance_variable_set("@#{id}_page".to_sym, page)
    end
  end

  def header()
    @header = LVGL::LVContainer.new(@screen)

    header_style = @header.get_style(LVGL::CONT_STYLE::MAIN).dup
    @header.set_style(LVGL::CONT_STYLE::MAIN, header_style)
    header_style.glass = 1
    header_style.body_radius = 0
    #header_style.body_main_color = 0xFF0000FF
    #header_style.body_grad_color = 0xFF0000FF

    @header.set_fit2(LVGL::FIT::FILL, LVGL::FIT::TIGHT)
    @header.set_layout(LVGL::LAYOUT::PRETTY)

    # Split 50/50
    child_width = (
      @screen.get_width -
      header_style.body_padding_left -
      header_style.body_padding_right -
      header_style.body_padding_inner*2
    ) / 2

    @clock = Clock.new(@header)
    @clock.set_width(child_width)

    @tagline = LVGL::LVLabel.new(@header)
    @tagline.set_text("Recovery Menu")
    @tagline.set_long_mode(LVGL::LABEL_LONG::SROLL_CIRC)
    @tagline.set_align(LVGL::LABEL_ALIGN::RIGHT)
    @tagline.set_width(child_width)
  end

  def logo()
    file = nil
    file = "/etc/logo.svg" if File.exist?("/etc/logo.svg")
    file = "./logo.svg" if File.exist?("./logo.svg")
    unless file
      return
    end
    if @screen.get_height > @screen.get_width
      LVGL::LVNanoSVG.resize_next_width((@screen.get_width_fit * 0.8).to_i)
    else
      # Detecting the available space where the layout will stretch into is
      # apparently hard with lvgl, thus we rely on the vertical resolution.
      # Meh, that's not *so* bad.
      # While it's a crude approximation, for layouting it's fine.
      LVGL::LVNanoSVG.resize_next_height((@screen.get_height * 0.15).to_i)
    end

    @logo = LVGL::LVImage.new(@screen)
    @logo.set_src(file)
  end

  def button(label, page: nil)
    if page
      page = instance_variable_get("@#{page}_page".to_sym)
    else
      page = @default_page
    end

    btn = LVGL::LVButton.new(page)
    btn.set_layout(LVGL::LAYOUT::COL_M)
    btn.set_ink_in_time(200)
    btn.set_ink_wait_time(100)
    btn.set_ink_out_time(500)
    btn.set_fit2(LVGL::FIT::FILL, LVGL::FIT::TIGHT)
    btn.glue_obj(true)

    LVGL::LVLabel.new(btn).tap do |obj|
      obj.set_text(label)
    end

    btn
  end
end

# Create the UI
ui = UI.new

def run(*cmd)
  $stderr.puts " $ " + cmd.join(" ")
  # TODO: better introspection to allow the app to know it is running in a
  # simulated environment, and dry-run in simulator.
  system(*cmd)
end

# TODO: wait ~0.3s for the animation before doing the button actions.
# Otherwise, it looks jarring.

# Default tab

ui.button("Reboot to bootloader").tap do |btn|
  btn.event_handler = ->(event) do
    case event
    when LVGL::EVENT::CLICKED
      run("reboot bootloader")
    end
  end
end

ui.button("Reboot to recovery").tap do |btn|
  btn.event_handler = ->(event) do
    case event
    when LVGL::EVENT::CLICKED
      run("reboot recovery")
    end
  end
end

ui.button("Reboot to system").tap do |btn|
  btn.event_handler = ->(event) do
    case event
    when LVGL::EVENT::CLICKED
      run("reboot")
    end
  end
end

ui.button("Power off").tap do |btn|
  btn.event_handler = ->(event) do
    case event
    when LVGL::EVENT::CLICKED
      run("poweroff")
    end
  end
end

# Generations tab

JSON.parse(File.read("/run/boot/selection.json")).each do |selection|
  ui.button(selection["name"], page: :generations).tap do |btn|
    btn.event_handler = ->(event) do
      case event
      when LVGL::EVENT::CLICKED
        File.write("/run/boot/choice", selection["id"])
        exit 0
      end
    end
  end
end

# Main loop
while true
  LVGL::Hacks::LVTask.handle_tasks
  sleep(1.0/REFRESH_RATE)
  # TODO : Allow exiting!
end

# Put back the console on the framebuffer
VTConsole.map_console(1)
