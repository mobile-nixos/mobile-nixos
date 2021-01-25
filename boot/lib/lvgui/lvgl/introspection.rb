module LVGL::Introspection
  def self.debug?()
    LVGL::FFI.lv_introspection_is_debug != 0
  end
  def self.simulator?()
    LVGL::FFI.lv_introspection_is_simulator != 0
  end
  def self.use_assert_style?()
    LVGL::FFI.lv_introspection_use_assert_style != 0
  end
  def self.display_driver()
    LVGL::FFI.lv_introspection_display_driver
  end
end
