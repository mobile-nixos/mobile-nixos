class MobileNixOS::EnhancedHeaderBar < LVGUI::HeaderBar
  def portrait?()
    @parent.get_width() < @parent.get_height() 
  end

  def initialize(parent)
    @parent = parent

    # In landscape mode, take less space.
    scale_factor =
      if portrait?
        1.0
      else
        1.0/2
      end

    # Wrap the header bar so we can constrain to 720 scaled pixels wide.
    # The contents will be centered.
    @container = LVGL::LVContainer.new(parent)
    @container.set_fit2(LVGL::FIT::NONE, LVGL::FIT::NONE)
    @container.set_layout(LVGL::LAYOUT::COL_M)
    @container.set_height(LVGUI.pixel_scale(128*scale_factor))
    @container.set_width(parent.get_width())
    super(@container)
    @container.set_style(LVGL::CONT_STYLE::MAIN, self.get_style(LVGL::CONT_STYLE::MAIN))
    self.set_style(LVGL::CONT_STYLE::MAIN, LVGL::LVStyle::STYLE_TRANSP)

    logo_path = LVGL::Hacks.get_asset_path("logo.svg")
    if File.exist?(logo_path)
      set_fit2(LVGL::FIT::NONE, LVGL::FIT::NONE)
      set_layout(LVGL::LAYOUT::OFF)
      set_height(LVGUI.pixel_scale(@container.get_height()))
      set_width(LVGUI.pixel_scale(720))

      @logo = LVGL::LVImage.new(self).tap do |el|
        el.set_height(LVGUI.pixel_scale(82*scale_factor))
        el.set_width(LVGUI.pixel_scale(375*scale_factor))
        el.set_x(LVGUI.pixel_scale(19*scale_factor))
        el.set_y(LVGUI.pixel_scale(25*scale_factor))
        el.set_src("#{logo_path}?height=#{el.get_height()}")
      end

      # We don't scale the label text size by design.
      # Instead we move it a bit differently
      @label.set_width(LVGUI.pixel_scale(720) - @logo.get_width_fit() - LVGUI.col_padding*2)
      @label.set_align(LVGL::LABEL_ALIGN::CENTER)
      if portrait?
        @label.set_y(LVGUI.pixel_scale(62*scale_factor))
      else
        @label.set_y(LVGUI.pixel_scale(28*scale_factor))
      end
      @label.set_x([
        @logo.get_x(),
        @logo.get_width(),
        LVGUI.col_padding,
      ].inject(&:+))
    end
  end
end
