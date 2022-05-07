module GUI; end

class GUI::MonospaceText < LVGUI::Widget
  def initialize(parent)
    super(LVGL::LVLabel.new(parent))

    get_style(LVGL::LABEL_STYLE::MAIN).dup().tap do |style|
      set_style(LVGL::LABEL_STYLE::MAIN, style)
      style.text_font = LVGUI::Fonts.monospace(16)
      style.text_color = 0xFFFFFFFF
    end

    set_long_mode(LVGL::LABEL_LONG::BREAK)
    set_align(LVGL::LABEL_ALIGN::LEFT)
    set_width(parent.get_width_fit())

    set_text("")
  end
end
