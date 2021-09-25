module LVGL::Introspection
  def self.debug?()
    LVGUI::Native.lv_introspection_is_debug != 0
  end
  def self.simulator?()
    LVGUI::Native.lv_introspection_is_simulator != 0
  end
  def self.use_assert_style?()
    LVGUI::Native.lv_introspection_use_assert_style != 0
  end
  def self.display_driver()
    LVGUI::Native.lv_introspection_display_driver
  end
end
