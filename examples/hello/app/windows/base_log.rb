module GUI
  class BaseLogWindow < BaseWindow
    include ButtonPalette
    def initialize(explanation:)
      super()
      BackButton.new(@toolbar, MainWindow.instance)
      @explanation = LVGL::LVLabel.new(@toolbar).tap do |label|
        label.set_long_mode(LVGL::LABEL_LONG::SROLL_CIRC)
        label.set_align(LVGL::LABEL_ALIGN::CENTER)
        label.set_y(@toolbar.get_height + @toolbar.get_style(LVGL::CONT_STYLE::MAIN).body_padding_inner)
        label.set_width(@toolbar.get_width_fit)
        label.set_text(explanation)
      end
      @container.refresh
      @container.set_scrl_layout(LVGL::LAYOUT::COL_R)
    end

    def set_text(text)
      @container.clean
      text.split("\n").each do |line|
        LVGL::LVLabel.new(@container).tap do |label|
          label.set_long_mode(LVGL::LABEL_LONG::BREAK)
          label.set_align(LVGL::LABEL_ALIGN::LEFT)
          label.set_width(@container.get_width_fit)
          label.set_text(line)
        end
      end
    end
  end
end
