module GUI
  class DisplayValidationWindow < LVGUI::BaseWindow
    include LVGUI::ButtonPalette
    include LVGUI::Window::WithBackButton
    goes_back_to ->() { MainWindow.instance }

    def initialize()
      super()

      LVGL::LVLabel.new(@container).tap do |label|
text = <<EOF
Defaults drivers on some devices, mainly Qualcomm devices, may have an unexpected ordering for pixels in-driver.

Those drivers will implement the basic minimum and RGB order support is not implemented.

A patch may be necessary if the following words are in the wrong colour.

The most common case is "Red" being blue, "Green" being green, and "Blue" being red. If it is the case, the keyword to search for patches is "BGR" or "BGRA".

EOF
        label.set_long_mode(LVGL::LABEL_LONG::BREAK)
        label.set_text(text)
        label.set_align(LVGL::LABEL_ALIGN::CENTER)
        label.set_width(@container.get_width_fit)
      end

      word("Red",   0xFF0000)
      word("Green", 0x00FF00)
      word("Blue",  0x0000FF)


      LVGL::LVLabel.new(@container).tap do |label|
text = <<EOF

LVGUI is currently using the "#{LVGL::Introspection.display_driver}" display driver.

EOF
        label.set_long_mode(LVGL::LABEL_LONG::BREAK)
        label.set_text(text)
        label.set_align(LVGL::LABEL_ALIGN::CENTER)
        label.set_width(@container.get_width_fit)
      end
    end

    def word(text, color)
      color = color % 0xFFFFFF
      LVGL::LVLabel.new(@container).tap do |label|
        label.set_long_mode(LVGL::LABEL_LONG::BREAK)
        label.set_text(text)
        style = label.get_style(LVGL::CONT_STYLE::MAIN).dup
        label.set_style(LVGL::CONT_STYLE::MAIN, style)
        style.text_color = 0xFF000000 + color
        label.set_align(LVGL::LABEL_ALIGN::CENTER)
        label.set_width(@container.get_width_fit)
      end
    end
  end
end
