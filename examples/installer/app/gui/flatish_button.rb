module GUI; end

class GUI::FlatishButton < LVGUI::Widget
  def initialize(parent)
    super(GUI::FlatishButton::Base.new(parent))

    # Add a container for the labels
    @label_container = LVGL::LVContainer.new(self).tap do |container|
      tr_style = LVGL::LVStyle::STYLE_TRANSP.dup
      tr_style.body_padding_left = 0
      tr_style.body_padding_right = 0
      container.set_style(LVGL::CONT_STYLE::MAIN, tr_style)

      # The layout is a column, two distinct lines, top to bottom.
      container.set_layout(LVGL::LAYOUT::COL_L)

      # Width will be computed in set_width; automatic layout from LVGL fails.
      container.set_fit2(LVGL::FIT::NONE, LVGL::FIT::TIGHT)

      container.set_click(false)
    end

    # Add the main label
    @main_label = LVGL::LVLabel.new(@label_container).tap do |label|
      label.set_long_mode(LVGL::LABEL_LONG::BREAK)
      label.set_click(false)
    end
    set_label("")

    # The secondary option label (second row, optional)
    @secondary_label = LVGL::LVLabel.new(@label_container).tap do |label|
      style = label.get_style(LVGL::LABEL_STYLE::MAIN).dup()
      # It's a bit more subdued
      style.text_color = 0xee_f1f1ff
      label.set_style(LVGL::LABEL_STYLE::MAIN, style)
      label.set_long_mode(LVGL::LABEL_LONG::BREAK)
      label.set_click(false)
      style.text_font = LVGUI::Fonts.primary(20)
    end
    set_secondary_label("")

    # Drill down icon
    @icon = LVGL::LVLabel.new(self).tap do |icon|
      icon.set_text("\uF054")
      icon.set_click(false)
    end

    # Call on @widget since we re-define event_handler=() for users of this class.
    @widget.event_handler = ->(event) {
      case event
      when LVGL::EVENT::RELEASED
        event_handler.call()
      end
    }

    # Defaults to full width
    self.set_width(parent.get_width_fit())
  end

  # Like the parent function.
  # Also recomputes the layout of internal elements
  def set_width(width)
    super(width)

    # Resize the label container to fill, working around segfault.
    @label_container.set_width(self.get_width_fit - @icon.get_width - LVGUI.col_padding()*1)
    @main_label.set_width(@label_container.get_width_fit)
    @secondary_label.set_width(@label_container.get_width_fit)
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
  def set_secondary_label(text)
    @secondary_label.set_text(text)
    if text
      @secondary_label.set_hidden(false)
    else
      @secondary_label.set_hidden(true)
    end
  end

  def event_handler=(prc)
    @event_handler = prc
  end

  def event_handler()
    @event_handler
  end
end

class GUI::FlatishButton::Base < LVGUI::Widget
  def initialize(parent)
    super(LVGL::LVButton.new(parent))

    # Styles
    [
      :REL,
      :PR,
      :TGL_REL,
      :TGL_PR,
      :INA,
    ].each do |sym|
      get_style(LVGL::BTN_STYLE.const_get(sym)).dup.tap do |style|
        style.body_radius = LVGUI.pixel_scale(16)
        style.body_padding_left = LVGUI.pixel_scale(24)
        style.body_padding_right = LVGUI.pixel_scale(6)
        style.body_padding_top = style.body_padding_top / 2
        style.body_padding_bottom = style.body_padding_bottom / 2
        set_style(LVGL::BTN_STYLE.const_get(sym), style)
      end
    end

    get_style(LVGL::BTN_STYLE::REL).dup.tap do |style|
      set_style(LVGL::BTN_STYLE::REL, style)
    end

    set_ink_in_time(200)
    set_ink_wait_time(100)
    set_ink_out_time(500)

    # Set layout for the line, labels left, "drill down icon" right, so a row.
    set_layout(LVGL::LAYOUT::ROW_M)
    set_fit2(LVGL::FIT::NONE, LVGL::FIT::TIGHT)
  end
end
