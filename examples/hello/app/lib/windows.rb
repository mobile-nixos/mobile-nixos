module GUI
  # Helper methods to help creating a "button palette" kind of window.
  module ButtonPalette
    def add_button(label)
      Button.new(@container).tap do |btn|
        btn.glue_obj(true)
        btn.set_label(label)
        btn.event_handler = ->(event) do
          case event
          when LVGL::EVENT::CLICKED
            yield
          end
        end
      end
    end

    def add_buttons(list)
      list.each do |pair|
        label, action = pair
        add_button(label, &action)
      end
    end
  end

  class MainWindow < BaseWindow
    include ButtonPalette
    def initialize()
      super()

      LVGL::LVLabel.new(@container).tap do |label|
        label.set_long_mode(LVGL::LABEL_LONG::BREAK)
        label.set_text(%Q{\nSelect from the following options})
        label.set_align(LVGL::LABEL_ALIGN::CENTER)
        label.set_width(@container.get_width_fit)
      end

      add_buttons([
        ["Display validation", ->() { DisplayValidationWindow.instance.present }],
        ["About", ->() { AboutWindow.instance.present }],
        ["Quit",  ->() { QuitWindow.instance.present }],
      ])
    end
  end

  class QuitWindow < BaseWindow
    include ButtonPalette

    def run(*cmd)
      $stderr.puts " $ " + cmd.join(" ")
      system(*cmd) unless LVGL::Introspection.simulator?
    end

    def initialize()
      super()
      BackButton.new(@container, MainWindow.instance)

      add_buttons([
        ["Reboot", ->() { run("reboot") }],
        ["Reboot to recovery", ->() { run("reboot recovery") }],
        ["Reboot to bootloader", ->() { run("reboot bootloader") }],
        ["Power off", ->() { run("poweroff") }],
      ])

      if LVGL::Introspection.simulator?
        add_button("Quit") {  exit(0) }
      end
    end
  end

  class AboutWindow < BaseWindow
    include ButtonPalette
    def initialize()
      super()
      BackButton.new(@container, MainWindow.instance)

      LVGL::LVLabel.new(@container).tap do |label|
text = <<EOF
Mobile NixOS "Hello GUI"

This application is intended to provide a minimum viable known working framebuffer application to test different components of your mobile device.

This is NOT a complete useful system.
EOF
        label.set_long_mode(LVGL::LABEL_LONG::BREAK)
        label.set_text(%Q{\n#{text}})
        label.set_align(LVGL::LABEL_ALIGN::CENTER)
        label.set_width(@container.get_width_fit)
      end
    end
  end

  class DisplayValidationWindow < BaseWindow
    include ButtonPalette
    def initialize()
      super()
      BackButton.new(@container, MainWindow.instance)

      LVGL::LVLabel.new(@container).tap do |label|
text = <<EOF
Defaults drivers on some devices, mainly Qualcomm devices, may have an unexpected ordering for pixels in-driver.

Those drivers will implement the basic minimum and RGB order support is not implemented.

A patch may be necessary if the following words are in the wrong colour.

The most common case is "Red" being blue, "Green" being green, and "Blue" being red. If it is the case, the keyword to search for patches is "BGR" or "BGRA".

EOF
        label.set_long_mode(LVGL::LABEL_LONG::BREAK)
        label.set_text(%Q{\n#{text}})
        label.set_align(LVGL::LABEL_ALIGN::CENTER)
        label.set_width(@container.get_width_fit)
      end

      word("Red",   0xFF0000)
      word("Green", 0x00FF00)
      word("Blue",  0x0000FF)
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
