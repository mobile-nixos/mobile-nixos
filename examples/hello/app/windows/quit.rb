module GUI
  class QuitWindow < LVGUI::BaseWindow
    include LVGUI::ButtonPalette
    include LVGUI::Window::WithBackButton
    goes_back_to ->() { MainWindow.instance }

    def run(*cmd)
      $stderr.puts " $ " + cmd.join(" ")
      system(*cmd) unless LVGL::Introspection.simulator?
    end

    def initialize()
      super()

      add_buttons([
        ["Reboot", ->() { run("reboot") }],
        ["Power off", ->() { run("poweroff") }],
      ])

      if LVGL::Introspection.simulator?
        add_button("Quit") { exit(0) }
      end
    end
  end
end
