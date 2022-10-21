# Wraps a raw +lv_ta+ in minimal helpers
class LVGUI::TextArea < LVGUI::Widget
  attr_reader :hidden
  attr_reader :animation_length

  def initialize(parent)
    super(LVGL::LVTextArea.new(parent))

    @animation_length = 400

    @hidden = false
    set_text("")
    set_placeholder_text("")
    set_one_line(true)
    set_opa_scale_enable(true)
    set_cursor_type(get_cursor_type() | LVGL::CURSOR::HIDDEN)

    self.event_handler = -> (event) do
      return if hidden()
      case event
      when LVGL::EVENT::CLICKED
        LVGUI::Keyboard.instance.set_ta(self)
        LVGUI::Keyboard.instance.show()
        @on_click.call() if @on_click
      when LVGL::EVENT::INSERT
        # Not exactly right, but right enough.
        char = LVGUI::Native.lv_event_get_data().ref_to_char()
        # Assume there is only one input.
        # Also assume Enter sends; that it is a single line.
        if char == "\n"
          LVGUI::Keyboard.instance.set_ta(nil)
          LVGUI::Keyboard.instance.hide()
          # Ensures the field is updated, then call the callback
          LVGL::Hacks::LVTask.once ->() do
            @on_submit.call(get_text()) if @on_submit
          end
        else
          # Ensures the field is updated, then call the callback
          LVGL::Hacks::LVTask.once ->() do
            @on_modified.call(get_text()) if @on_modified
          end
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
      anim.set_time(@animation_length, 0)
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
      anim.set_time(@animation_length, 0)
      anim.set_values(255, 0)
      anim.set_path_cb(LVGL::LVAnim::Path::EASE_IN)

      # Launch the animation
      anim.create()
    end
  end

  def on_click=(cb)
    @on_click = cb
  end
  def on_modified=(cb)
    @on_modified = cb
  end
  def on_submit=(cb)
    @on_submit = cb
  end
end
