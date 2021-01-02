# Wraps a raw +lv_ta+ in minimal helpers
class LVGUI::TextArea < LVGUI::Widget
  attr_reader :hidden

  def initialize(parent)
    super(LVGL::LVTextArea.new(parent))

    @hidden = false
    set_text("")
    set_placeholder_text("")
    set_pwd_mode(true)
    set_one_line(true)
    set_opa_scale_enable(true)
    get_style(LVGL::TA_STYLE::BG).dup.tap do |style|
      set_style(LVGL::TA_STYLE::BG, style)
      style.body_main_color = 0xFF000000
      style.body_grad_color = 0xFF000000
      style.body_radius = 5
      style.body_border_color = 0xFFFFFFFF
      style.body_border_width = 3
      style.body_border_opa = 255
      style.text_color = 0xFFFFFFFF
    end
    get_style(LVGL::TA_STYLE::PLACEHOLDER).dup.tap do |style|
      set_style(LVGL::TA_STYLE::PLACEHOLDER, style)
      style.text_color = 0xFFAAAAAA
    end
    set_cursor_type(get_cursor_type() | LVGL::CURSOR::HIDDEN)

    self.event_handler = -> (event) do
      return if hidden()
      case event
      when LVGL::EVENT::CLICKED
        LVGUI::Keyboard.instance.set_ta(self)
        LVGUI::Keyboard.instance.show()
      when LVGL::EVENT::INSERT
        # Not exactly right, but right enough.
        char = LVGL::FFI.lv_event_get_data().to_str(1)
        # Assume there is only one input.
        # Also assume Enter sends; that it is a single line.
        if char == "\n"
          LVGUI::Keyboard.instance.set_ta(nil)
          LVGUI::Keyboard.instance.hide()
          # Create a new string
          # get_text() gives us a Fiddle::Pointer (leaky abstraction!!!)
          value = "#{get_text()}"
          @on_submit.call(value) if @on_submit
          hide()
        end
      #else
      #  puts "Unhandled event for #{self}: #{LVGL::EVENT.from_value(event)}"
      end
    end
  end

  def show()
    @hidden = false
    LVGL::LVAnim.new().tap do |anim|
      anim.set_exec_cb(self, :lv_obj_set_opa_scale)
      anim.set_time(FADE_LENGTH, 0)
      anim.set_values(0, 255)
      anim.set_path_cb(LVGL::LVAnim::Path::EASE_OUT)

      # Launch the animation
      anim.create()
    end
  end

  def hide(skip_animation: false)
    @hidden = true
    if skip_animation
      set_opa_scale(0)
      return
    end

    LVGL::LVAnim.new().tap do |anim|
      anim.set_exec_cb(self, :lv_obj_set_opa_scale)
      anim.set_time(FADE_LENGTH, 0)
      anim.set_values(255, 0)
      anim.set_path_cb(LVGL::LVAnim::Path::EASE_IN)

      # Launch the animation
      anim.create()
    end
  end

  def on_submit=(cb)
    @on_submit = cb
  end
end
