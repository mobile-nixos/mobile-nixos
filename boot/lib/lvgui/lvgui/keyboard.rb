# Wraps a raw +lv_keyboard+ in minimal helpers
# This is intended to be used as a singleton instance, where you can
# "re-parent" the keyboard as needed.
class LVGUI::Keyboard < LVGUI::Widget
  include Singleton

  attr_accessor :animation_duration
  attr_accessor :container

  private

  def initialize()
    @shown = false
    @animation_duration = 300
    # Attach the keyboard to the current active screen, by default.
    super(LVGL::LVKeyboard.new(LVGL::LVDisplay.get_scr_act()))
    set_cursor_manage(true)

    get_style(LVGL::KB_STYLE::BG).dup.tap do |style|
      set_style(LVGL::KB_STYLE::BG, style)
      padding = 4
      style.body_padding_top = padding
      style.body_padding_left = padding
      style.body_padding_right = padding
      style.body_padding_bottom = padding
      style.body_padding_inner = padding
    end
    set_y(get_parent.get_height())
  end

  public

  def set_height(value)
    super(value)
    _set_position()
  end

  def get_visible_height()
    if @shown
      # FIXME: "animated height" to collapse container accordingly
      get_height()
    else
      0
    end
  end

  def show()
    raise "Parent not set" unless get_parent()
    @shown = true
    _animate_y(get_parent.get_height() - get_height())
    if @container
      @container.refresh()
      LVGL::Hacks::LVTask.once(->() do
        @container.focus(
          self.get_ta(),
          LVGL::ANIM::ON
        )
      end, prio: LVGL::TASK_PRIO::LOWEST)
    end
  end

  def hide()
    raise "Parent not set" unless get_parent()
    @shown = false
    _animate_y(get_parent.get_height)
    @container.refresh() if @container
  end

  def _set_position()
    raise "Parent not set" unless get_parent()
    if @shown
      _animate_y(get_parent.get_height() - get_height())
    else
      _animate_y(get_parent.get_height())
    end
  end

  def _animate_y(ending)
    LVGL::LVAnim.new().tap do |anim|
      anim.set_exec_cb(self, :lv_obj_set_y)
      anim.set_time(@animation_duration, 0)
      anim.set_values(get_y(), ending)
      anim.set_path_cb(LVGL::LVAnim::Path::EASE_OUT)

      # Launch the animation
      anim.create()
    end
  end
end
