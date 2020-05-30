module GUI
  class QuitWindow < BaseWindow
    include ButtonPalette

    def run(*cmd)
      $stderr.puts " $ " + cmd.join(" ")
      system(*cmd) unless LVGL::Introspection.simulator?
    end

    def initialize()
      super()
      BackButton.new(@container, MainWindow.instance)

      add_buttons([
        ["Reboot", ->() { run("reboot") }],
        ["Reboot to recovery", ->() { run("reboot recovery") }],
        ["Reboot to bootloader", ->() { run("reboot bootloader") }],
        ["Power off", ->() { run("poweroff") }],
      ])

      if LVGL::Introspection.simulator?
        add_button("Quit") { exit(0) }
      end
    end
  end
end
