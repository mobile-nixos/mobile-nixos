module Kernel
  alias_method :_exit, :exit

  # mruby-at_exit seems to not be complete :/
  # Let's instead hijack exit...
  def exit(*args)
    # Restore the console at exit.
    VTConsole.map_console(1)
    _exit(*args)
  end
end

class UI
  attr_reader :screen
  attr_reader :progress_bar

  # As this is not using BaseWindow, LVGUI::init isn't handled for us.
  LVGUI.init()

  def initialize()
    add_screen
    # Biggest of horizontal or vertical; a percent.
    @unit = ([@screen.get_width, @screen.get_height].max * 0.01).ceil
    add_logo
    add_progress_bar
    add_label

    add_cover # last
  end

  def add_label()
    @label = LVGL::LVLabel.new(@screen)
    @label.get_style(LVGL::LABEL_STYLE::MAIN).dup.tap do |style|
      @label.set_style(LVGL::LABEL_STYLE::MAIN, style)
      style.text_color = 0xFFFFFFFF
    end
    @label.set_long_mode(LVGL::LABEL_LONG::BREAK)
    @label.set_align(LVGL::LABEL_ALIGN::CENTER)

    @label.set_width(@screen.get_width * 0.9)
    @label.set_pos(*center(@label, 0, 5*@unit))
    @label.set_text("")
  end

  def add_logo()
    # Try to find the logo, but don't fail if there isn't one.
    file = nil
    file = "/etc/logo.svg" if File.exist?("/etc/logo.svg")
    file = "./logo.svg" if File.exist?("./logo.svg")
    return unless file

    if @screen.get_height > @screen.get_width
      # 80% of the width
      LVGL::Hacks::LVNanoSVG.resize_next_width((@screen.get_width * 0.8).to_i)
    else
      # 15% of the height
      LVGL::Hacks::LVNanoSVG.resize_next_height((@screen.get_height * 0.15).to_i)
    end

    @logo = LVGL::LVImage.new(@screen)
    @logo.set_src(file)

    # Position the logo
    @logo.set_pos(*center(@logo, 0, -@logo.get_height))
  end

  def add_progress_bar()
    @progress_bar = ProgressBar.new(@screen)
    @progress_bar.set_height(3 * @unit)
    @progress_bar.set_width(@screen.get_width * 0.7)
    @progress_bar.set_pos(*center(@progress_bar))
  end

  def add_screen()
    @screen = LVGL::LVContainer.new()
    @screen.get_style(LVGL::CONT_STYLE::MAIN).dup.tap do |style|
      @screen.set_style(LVGL::CONT_STYLE::MAIN, style)

      # Background for the splash, assumed black.
      style.body_main_color = 0xFF000000
      style.body_grad_color = 0xFF000000
    end
  end

  # Used to handle fade-in/fade-out
  # This is because opacity handles multiple overlaid objects wrong.
  def add_cover()
    @cover = LVGL::LVObject.new(@screen)
    # Make it so we can use the opacity to fade in/out
    @cover.set_opa_scale_enable(true)
    @cover.set_width(@screen.get_width())
    @cover.set_height(@screen.get_height())
    @cover.set_click(false)

    @cover.get_style().dup.tap do |style|
      @cover.set_style(style)

      # Background for the splash, assumed black.
      style.body_main_color = 0xFF000000
      style.body_grad_color = 0xFF000000
      # Some themes will add a border to LVObject.
      style.body_border_width = 0
    end
  end

  def set_progress(amount)
    progress_bar.progress = amount
  end

  def set_label(text)
    @label.set_text(text)
  end

  # Fade-in animation
  # Note that this looks like inverted logic because it is!
  # We're actually fading-out the cover!
  def fade_in()
    LVGL::LVAnim.new().tap do |anim|
      anim.set_exec_cb(@cover, :lv_obj_set_opa_scale)
      anim.set_time(FADE_LENGTH, 0)
      anim.set_values(255, 0)
      anim.set_path_cb(LVGL::LVAnim::Path::EASE_OUT)

      # Launch the animation
      anim.create()
    end
  end

  # Fade-out animation
  # Note that this looks like inverted logic because it is!
  # We're actually fading-in the cover!
  def fade_out()
    LVGL::LVAnim.new().tap do |anim|
      anim.set_exec_cb(@cover, :lv_obj_set_opa_scale)
      anim.set_time(FADE_LENGTH, PROGRESS_UPDATE_LENGTH)
      anim.set_values(0, 255)
      anim.set_path_cb(LVGL::LVAnim::Path::EASE_IN)

      # Launch the animation
      anim.create()
    end
  end

  def quit!()
    fade_out()
    set_progress(100)

    # TODO: Callback on a timer or on the fade_out animation end.
    # Though we **do** want to stop processing from the queue.
    # This is not a callback yet because we don't have an ergonomic way to
    # produce those callbacks for LVGL yet.
    exit_timestamp = Time.now + FADE_LENGTH/1000.0 + PROGRESS_UPDATE_LENGTH/1000.0 + 0.1
    LVGUI.main_loop do
      if Time.now > exit_timestamp
        sleep(2) if LVGL::Introspection.simulator?
        exit(0)
      end
    end
    # (end TODO)
  end

  private

  def center(el, x = 0, y = 0)
    [
      @screen.get_width  / 2 - el.get_width  / 2 + x,
      @screen.get_height / 2 - el.get_height / 2 + y,
    ]
  end
end


