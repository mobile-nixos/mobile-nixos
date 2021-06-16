module GUI
  class MainWindow < LVGUI::BaseWindow
    include LVGUI::BaseUIElements
    include LVGUI::ButtonPalette
    def initialize()
      super()

      add_main_text(%Q{[...] to be done...})

      add_buttons([
        ["Quit",  ->() { QuitWindow.instance.present }],
      ])
    end
  end
end
