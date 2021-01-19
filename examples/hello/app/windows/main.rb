module GUI
  class MainWindow < LVGUI::BaseWindow
    include LVGUI::BaseUIElements
    include LVGUI::ButtonPalette
    def initialize()
      super()

      add_main_text(%Q{Your device booted to\nstage-2 of a NixOS system successfully!\n\nSelect from the following options})

      add_buttons([
        ["Display validation", ->() { DisplayValidationWindow.instance.present }],
        ["Input devices information", ->() { InputsWindow.instance.present }],
        ["Disks information", ->() { DisksWindow.instance.present }],
        ["Logs", ->() { LogsWindow.instance.present }],
        ["About", ->() { AboutWindow.instance.present }],
        ["Quit",  ->() { QuitWindow.instance.present }],
      ])
    end
  end
end
