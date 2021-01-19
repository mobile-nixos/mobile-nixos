# Wraps an +lv_sw+ and other elements into a widget intended to be added as a
# line to a window.
# This imitates the common control found in mobile UIs.
class LVGUI::SwitchLine < LVGUI::Widget
  def initialize(parent)
    super(LVGL::LVContainer.new(parent))

    # Remove container "presence"
    tr_style = LVGL::LVStyle::STYLE_TRANSP.dup
    tr_style.body_padding_left = 0
    tr_style.body_padding_right = 0
    set_style(LVGL::CONT_STYLE::MAIN, tr_style)

    # Set layout for the line, labels left, toggle right, so a row.
    set_layout(LVGL::LAYOUT::ROW_M)
    set_fit2(LVGL::FIT::FILL, LVGL::FIT::TIGHT)

    # Add a container for the labels
    @label_container = LVGL::LVContainer.new(self).tap do |container|
      tr_style = LVGL::LVStyle::STYLE_TRANSP.dup
      container.set_style(LVGL::CONT_STYLE::MAIN, tr_style)

      # The layout is a column, two distinct lines, top to bottom.
      container.set_layout(LVGL::LAYOUT::COL_L)

      # segfault on horizontal fill here...
      container.set_fit2(LVGL::FIT::NONE, LVGL::FIT::TIGHT)
    end

    # Add the main label
    @main_label = LVGL::LVLabel.new(@label_container).tap do |label|
      label.set_long_mode(LVGL::LABEL_LONG::BREAK)
    end
    set_label(nil)

    # The description label (second row, optional)
    @description_label = LVGL::LVLabel.new(@label_container).tap do |label|
      style = label.get_style(LVGL::LABEL_STYLE::MAIN).dup()
      # It's a bit more subdued
      style.text_color = 0xffaaaaaa
      label.set_style(LVGL::LABEL_STYLE::MAIN, style)
      label.set_long_mode(LVGL::LABEL_LONG::BREAK)
    end
    set_description(nil)

    # Add the actual toggle control
    @switch = LVGL::LVSwitch.new(self)

    padding = @label_container.get_style(LVGL::CONT_STYLE::MAIN).body_padding_inner
    # Resize the label container to fill, working around segfault.
    @label_container.set_width(self.get_width - @switch.get_width - padding)
    @main_label.set_width(@label_container.get_width)
    @description_label.set_width(@label_container.get_width)
  end

  # Sets the main label, optionally hiding it.
  # When hidden, it takes no vertical space in the layout.
  def set_label(text)
    @main_label.set_text(text)
    if text
      @main_label.set_hidden(false)
    else
      @main_label.set_hidden(true)
    end
  end

  # Sets the description label, optionally hiding it.
  # When hidden, it takes no vertical space in the layout.
  def set_description(text)
    @description_label.set_text(text)
    if text
      @description_label.set_hidden(false)
    else
      @description_label.set_hidden(true)
    end
  end

  # Hook the handler to the toggle *and* the whole row.
  def event_handler=(handler)
    # Directly hook the handler to the switch event handler
    @switch.event_handler=(handler)

    # Proc to hook the same event on multiple UI elements
    delegate_to_switch = ->(event) {
      case event
      when LVGL::EVENT::RELEASED
        @switch.toggle(true)
        @switch.event_handler.call(LVGL::EVENT::VALUE_CHANGED)
      end
    }

    # Hook on the row, otherwise we get a small dead zone in the padding
    # between the toggle and the label container
    @widget.event_handler=(delegate_to_switch)
    # Then also hook to the label container
    @label_container.event_handler=(delegate_to_switch)
  end

  def event_handler()
    @switch.event_handler
  end

  # Proxies a few functions to the switch

  def on(*args)
    @switch.on(*args)
  end

  def off(*args)
    @switch.off(*args)
  end

  def toggle(*args)
    @switch.toggle(*args)
  end

  def get_state()
    @switch.get_state()
  end

  # Access the actual control.
  # This is meant to be used so this can be added to the focus group.
  def switch_control()
    @switch
  end
end
