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

LVGUI.init

# Implements a clock as a wrapped LVLabel.
class Clock < LVGUI::Widget
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
    now = Time.now
    set_text([
      :hour,
      :min,
      :sec,
    ].map{|fn| now.send(fn).to_s.rjust(2, "0") }.join(":"))
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
    setup_container
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

  def setup_container()
    @container = LVGL::LVContainer.new(@screen)
    @container.set_height(@screen.get_height - @container.get_y)
    @container.set_width(@screen.get_width)
    @container.set_layout(LVGL::LAYOUT::COL_M)
    @container.set_style(LVGL::CONT_STYLE::MAIN, LVGL::LVStyle::STYLE_TRANSP)
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
    @tagline.set_text("JumpDrive applet")
    @tagline.set_long_mode(LVGL::LABEL_LONG::SROLL_CIRC)
    @tagline.set_align(LVGL::LABEL_ALIGN::RIGHT)
    @tagline.set_width(child_width)
  end

  def logo()
    file = nil
    file = "/etc/logo.svg" if File.exist?("/etc/logo.svg")
    file = "./logo.svg" if File.exist?("./logo.svg")
    return unless file

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

  def button(label)
    btn = LVGL::LVButton.new(@container)
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

  def label(text)
    main = LVGL::LVLabel.new(@container)
    main.set_text(text)
    main.set_align(LVGL::LABEL_ALIGN::CENTER)
  end
end

# Create the UI
ui = UI.new

def run(*cmd)
  $stderr.puts " $ " + cmd.join(" ")
  system(*cmd) unless LVGL::Hacks.simulator?
end

# TODO: At some point, allow selecting the storage device to present.
# Though, this will need better coordination with a "gadget mode tool" system
# that will be able to re-do the USB gadget work.

ui.label("Your device should act as a USB mass storage.")
ui.label("")
ui.label("Eject it from your system before rebooting.")
ui.label("")
ui.label("")

ui.button("Reboot device").tap do |btn|
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

LVGUI.mainloop
