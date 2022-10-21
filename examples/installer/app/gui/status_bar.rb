class LVGUI::StatusBar
  alias_method :_initialize, :initialize
  def initialize(*args)
    _initialize(*args)

    child_width = @battery.get_width()
    # We remove the battery, and will replace with our own status widget.
    @battery.del
    @battery = nil

    @status_icons = GUI::StatusIcons.new(self)
    @status_icons.instance_exec do
      get_style(LVGL::LABEL_STYLE::MAIN).dup().tap do |style|
        set_style(LVGL::LABEL_STYLE::MAIN, style)
        style.text_font = LVGUI::Fonts.primary(19)
      end
      set_height(LVGUI.point_scale(19))
      set_width(child_width)
    end
  end
end
