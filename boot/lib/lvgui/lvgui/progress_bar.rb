class LVGUI::ProgressBar < LVGUI::Widget
  def initialize(parent)
    super(LVGL::LVContainer.new(parent))

    get_style(LVGL::CONT_STYLE::MAIN).dup().tap do |style|
      set_style(LVGL::CONT_STYLE::MAIN, style)
      style.body_main_color = 0x00000000
      style.body_grad_color = 0x00000000
      style.body_border_width = 0
      style.body_radius = 0
    end

    # Add an LVObject we'll use to render a rectangle for the background of the
    # progress bar.
    @background = LVGL::LVObject.new(self)
    @background.get_style().dup.tap do |style|
      @background.set_style(style)
      style.body_main_color = 0xFF000000
      style.body_grad_color = 0xFF000000
      style.body_radius = 5
      style.body_border_color = 0xFFFFFFFF
      style.body_border_width = 3
      style.body_border_opa = 255
    end

    # Add an LVObject we'll use to render a rectangle for the current progress.
    @progress = LVGL::LVObject.new(self)
    @progress.set_width(0)
    @background.get_style().dup.tap do |style|
      @progress.set_style(style)
      style.body_main_color = 0xFFFFFFFF
      style.body_grad_color = 0xFFFFFFFF
      style.body_border_width = 0
    end

    self.progress = 0
    refresh_sizes
  end

  def background_color=(color)
    get_style(LVGL::CONT_STYLE::MAIN).tap do |style|
      style.body_main_color = color
      style.body_grad_color = color
    end
    @background.get_style().tap do |style|
      style.body_main_color = color
      style.body_grad_color = color
    end
  end

  def foreground_color=(color)
    @background.get_style().tap do |style|
      style.body_border_color = color
    end
    @progress.get_style().tap do |style|
      style.body_main_color = color
      style.body_grad_color = color
    end
  end

  def refresh_sizes()
    width = get_width()
    [@background].each do |component|
      component.set_width(width)
    end
    height = get_height()
    [@background, @progress].each do |component|
      component.set_height(height)
    end
    refresh_progress()
  end

  def set_width(width)
    super(width)
    refresh_sizes()
  end

  def set_height(height)
    super(height)
    refresh_sizes()
  end

  def progress=(val)
    val = 100 if val > 100
    @changed = true
    @progress_amount = val
    refresh_progress()
  end

  def progress()
    @progress_amount
  end

  def refresh_progress()
    if @changed
      new_width = @progress_amount/100.0 * get_width()
      LVGL::LVAnim.new().tap do |anim|
        anim.set_exec_cb(@progress, :lv_obj_set_width)
        anim.set_time(PROGRESS_UPDATE_LENGTH, 0)
        anim.set_values(@progress.get_width, new_width)
        anim.set_path_cb(LVGL::LVAnim::Path::EASE_OUT)

        # Launch the animation
        anim.create()
      end
      @changed = false
    end
  end
end
