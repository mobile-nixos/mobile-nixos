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
  FG_COLOR = Configuration["splash"] && Configuration["splash"]["foreground"]
  FG_COLOR = FG_COLOR.to_i(16) if FG_COLOR.is_a?(String)
  FG_COLOR ||= 0xFFFFFFFF
  BG_COLOR = Configuration["splash"] && Configuration["splash"]["background"]
  BG_COLOR = BG_COLOR.to_i(16) if BG_COLOR.is_a?(String)
  BG_COLOR ||= 0xFF000000
  THEME = Configuration["splash"] && Configuration["splash"]["theme"]
  THEME ||= "night"

  attr_reader :screen
  attr_reader :progress_bar
  attr_reader :ask_identifier

  # As this is not using BaseWindow, LVGUI::init isn't handled for us.
  LVGUI.init(theme: THEME.to_sym, assets_path: "boot-splash/assets")

  def initialize()
    add_screen
    add_page
    # Biggest of horizontal or vertical; a percent.
    @unit = ([@screen.get_width, @screen.get_height].max * 0.01).ceil
    add_logo
    add_progress_bar
    add_label
    add_recovery

    add_textarea
    add_keyboard

    add_cover # last
  end

  def add_label()
    @label = LVGL::LVLabel.new(@page)
    @label.get_style(LVGL::LABEL_STYLE::MAIN).dup.tap do |style|
      @label.set_style(LVGL::LABEL_STYLE::MAIN, style)
      style.text_color = FG_COLOR
    end
    @label.set_long_mode(LVGL::LABEL_LONG::BREAK)
    @label.set_align(LVGL::LABEL_ALIGN::CENTER)

    @label.set_width(@page.get_width * 0.9)
    @label.set_pos(*center(@label, 0, 5*@unit))
    @label.set_text("")
  end

  def add_logo()
    file = LVGL::Hacks.get_asset_path("logo.svg")

    if @page.get_height > @page.get_width
      # 80% of the width
      file = "#{file}?width=#{(@page.get_width * 0.8).to_i}"
    else
      # 15% of the height
      file = "#{file}?height=#{(@page.get_height * 0.15).to_i}"
    end

    @logo = LVGL::LVImage.new(@page)
    @logo.set_src(file)

    # Position the logo
    @logo.set_pos(*center(@logo, 0, -@logo.get_height))
  end

  def add_progress_bar()
    @progress_bar = LVGUI::ProgressBar.new(@page)
    @progress_bar.set_height(3 * @unit)
    @progress_bar.set_width(@page.get_width * 0.7)
    @progress_bar.set_pos(*center(@progress_bar))
    @progress_bar.foreground_color = FG_COLOR
    @progress_bar.background_color = BG_COLOR
  end

  def add_screen()
    @screen = LVGL::LVContainer.new()
    # NOTE: we don't need to `#dup` the screen's style, it's unique.
    # (`#dup`ing it also crashes with the mono theme :/)
    @screen.get_style(LVGL::CONT_STYLE::MAIN).tap do |style|
      # Background for the splash, assumed black.
      style.body_main_color = BG_COLOR
      style.body_grad_color = BG_COLOR
    end
  end

  def add_page()
    @page = LVGL::LVContainer.new(@screen)
    @page.set_width(@screen.get_width)
    @page.set_height(@screen.get_height)
    @page.get_style(LVGL::CONT_STYLE::MAIN).dup.tap do |style|
      @page.set_style(LVGL::CONT_STYLE::MAIN, style)
      style.body_main_color = BG_COLOR
      style.body_grad_color = BG_COLOR
      style.body_border_width = 0
    end
  end

  def add_recovery()
    @recovery_container = LVGL::LVContainer.new(@page)
    @recovery_container.set_hidden(true)
    @recovery_container.set_width(@page.get_width)
    @recovery_container.get_style(LVGL::CONT_STYLE::MAIN).dup.tap do |style|
      @recovery_container.set_style(LVGL::CONT_STYLE::MAIN, style)
      style.body_main_color = BG_COLOR
      style.body_grad_color = BG_COLOR
      style.body_border_width = 0
    end

    recovery_label = LVGL::LVLabel.new(@recovery_container)
    recovery_label.get_style(LVGL::LABEL_STYLE::MAIN).dup.tap do |style|
      recovery_label.set_style(LVGL::LABEL_STYLE::MAIN, style)
      style.text_color = FG_COLOR
    end
    recovery_label.set_long_mode(LVGL::LABEL_LONG::BREAK)
    recovery_label.set_align(LVGL::LABEL_ALIGN::CENTER)

    recovery_label.set_width(@recovery_container.get_width() * 0.9)
    recovery_label.set_text("Booting to recovery menu")
    recovery_label.set_x(@recovery_container.get_width()/2 - recovery_label.get_width()/2)
    recovery_label.set_y(@unit)

    @recovery_container.set_height(recovery_label.get_height() + 2*@unit)
    @recovery_container.set_pos(0, @page.get_height() - @recovery_container.get_height())
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

      # Background for the splash
      style.body_main_color = BG_COLOR
      style.body_grad_color = BG_COLOR
      # Some themes will add a border to LVObject.
      style.body_border_width = 0
    end
  end

  def add_textarea()
    @ta = LVGUI::TextArea.new(@page)
    @ta.set_width(@page.get_width * 0.9)
    @ta.set_pos(*center(@ta, 0, @unit * 14))
    # Always present, but initially hidden
    @ta.hide(skip_animation: true)
    @ta.instance_exec do
      set_pwd_mode(true)
      get_style(LVGL::TA_STYLE::BG).dup.tap do |style|
        set_style(LVGL::TA_STYLE::BG, style)
        style.body_main_color = BG_COLOR
        style.body_grad_color = BG_COLOR
        style.body_radius = 5
        style.body_border_color = FG_COLOR
        style.body_border_width = 3
        style.body_border_opa = 255
        style.text_color = FG_COLOR
      end
      get_style(LVGL::TA_STYLE::PLACEHOLDER).dup.tap do |style|
        set_style(LVGL::TA_STYLE::PLACEHOLDER, style)
        style.text_color = LVGL::LVColor.mix(FG_COLOR, BG_COLOR, 100)
      end
    end

    LVGUI.focus_group.add_obj(@ta)
    LVGUI.focus_ring_disable()
  end

  def add_keyboard()
    @keyboard = LVGUI::Keyboard.instance()
    # The keyboard is not added to the page; the page holds the elements that
    # may move to ensure they're not covered by the keyboard.
    @keyboard.set_parent(@screen)
    # Keyboard can't be more than half of the screen height...
    # ... otherwise the UI is pushed too far up.
    @keyboard.set_height(
      (@screen.get_width() * 0.55).clamp(0, @screen.get_height()*0.5)
    )
  end

  def set_progress(amount)
    progress_bar.progress = amount
  end

  def set_label(text)
    @label.set_text(text)
  end

  # +cb+ is a proc that wille be +#call+'d with the text once submitted.
  def ask_user(placeholder: "", identifier: , cb:)
    return if identifier == @ask_identifier

    @ask_identifier = identifier
    @ta.set_placeholder_text(placeholder)
    @ta.set_text("")
    @ta.show()
    @keyboard.set_ta(@ta)
    @keyboard.show()

    bottom_space = @screen.get_height() - (@ta.get_y() + @ta.get_height())
    delta = bottom_space - @keyboard.get_height() - 3*@unit
    offset_page(delta) if delta < 0

    @ta.on_submit = ->(value) do
      @ta.hide()
      offset_page(0)
      cb.call(value)
    end
  end

  def show_recovery_notice(val = true)
    @recovery_container.set_hidden(!val)
  end

  def offset_page(delta)
    LVGL::LVAnim.new().tap do |anim|
      anim.set_exec_cb(@page, :lv_obj_set_y)
      anim.set_time(300, 0)
      anim.set_values(@page.get_y(), delta)
      anim.set_path_cb(LVGL::LVAnim::Path::EASE_OUT)

      # Launch the animation
      anim.create()
    end
  end

  # Fade-in animation
  # Note that this looks like inverted logic because it is!
  # We're actually fading-out the cover!
  def fade_in(fade_length)
    LVGL::LVAnim.new().tap do |anim|
      anim.set_exec_cb(@cover, :lv_obj_set_opa_scale)
      anim.set_time(fade_length, 0)
      anim.set_values(255, 0)
      anim.set_path_cb(LVGL::LVAnim::Path::EASE_OUT)

      # Launch the animation
      anim.create()
    end
  end

  # Fade-out animation
  # Note that this looks like inverted logic because it is!
  # We're actually fading-in the cover!
  def fade_out(fade_length)
    LVGL::LVAnim.new().tap do |anim|
      anim.set_exec_cb(@cover, :lv_obj_set_opa_scale)
      anim.set_time(fade_length, PROGRESS_UPDATE_LENGTH)
      anim.set_values(0, 255)
      anim.set_path_cb(LVGL::LVAnim::Path::EASE_IN)

      # Launch the animation
      anim.create()
    end
  end

  # Quits this applet, fading-out if needed.
  # @param sticky: when true no cleanup is done from the display.
  def quit!(sticky: false)
    fade_length = 0

    unless sticky
      fade_length = FADE_LENGTH
      fade_out(fade_length)
    end

    set_progress(100)

    # TODO: Callback on a timer or on the fade_out animation end.
    # Though we **do** want to stop processing from the queue.
    # This is not a callback yet because we don't have an ergonomic way to
    # produce those callbacks for LVGL yet.
    exit_timestamp = Time.now + fade_length/1000.0 + PROGRESS_UPDATE_LENGTH/1000.0 + 0.1
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


