GUI::MainWindow.instance.present

if LVGL::Introspection.simulator?
  LVGUI.main_loop do
    # Torture test
    GC.start()
  end
else
  LVGUI.main_loop
end
