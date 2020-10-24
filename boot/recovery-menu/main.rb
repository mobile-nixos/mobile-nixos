# File with boot selection
SELECTIONS = "/run/boot/selection.json"

# Runs and prints a command. Probably.
def run(*cmd)
  $stderr.puts " $ " + cmd.join(" ")
  system(*cmd) unless LVGL::Introspection.simulator?
end

module RebootModes
  Android = {
    "recovery"   => ["Reboot to recovery", ->() { run("reboot recovery") }],
    "bootloader" => ["Reboot to bootloader", ->() { run("reboot bootloader") }],
  }

  def self.options()
    [
      ["Reboot to system", ->() { run("reboot") }],
    ] + 
      Configuration["HAL"]["boot"]["rebootModes"].map do |identifier|
        const, key = identifier.split(".", 2)
        const_get(const)[key]
      end
  end
end

module BootGUI
  class MainWindow < LVGUI::BaseWindow
    include LVGUI::ButtonPalette

    # Add the logo to the view.
    def logo()
      # Try to find the logo, but don't fail if there isn't one.
      file = nil
      file = "/etc/logo.svg" if File.exist?("/etc/logo.svg")
      file = "./logo.svg" if File.exist?("./logo.svg")
      return unless file

      if @container.get_height > @container.get_width
        LVGL::Hacks::LVNanoSVG.resize_next_width((@container.get_width_fit * 0.8).to_i)
      else
        # Detecting the available space where the layout will stretch into is
        # apparently hard with lvgl, thus we rely on the vertical resolution.
        # Meh, that's not *so* bad.
        # While it's a crude approximation, for layouting it's fine.
        LVGL::Hacks::LVNanoSVG.resize_next_height((@container.get_height * 0.15).to_i)
      end

      @logo = LVGL::LVImage.new(@container)
      @logo.set_src(file)
    end

    def initialize()
      super()

      # Add the logo
      logo

      # An explanatory label
      LVGL::LVLabel.new(@container).tap do |label|
        label.set_long_mode(LVGL::LABEL_LONG::BREAK)
        label.set_text(%Q{Your device booted in recovery mode.})
        label.set_align(LVGL::LABEL_ALIGN::CENTER)
        label.set_width(@container.get_width_fit)
      end

      # Our buttons palette!
      add_buttons([
        ["Generations  #{LVGL::Symbols::RIGHT}", ->() { GenerationsWindow.instance.present }],
        *(RebootModes.options),
        ["Power off", ->() { run("poweroff") }],
      ])
    end
  end

  # Shows the list of generations to boot into.
  class GenerationsWindow < LVGUI::BaseWindow
    include LVGUI::ButtonPalette
    include LVGUI::Window::WithBackButton
    goes_back_to ->() { MainWindow.instance }

    def initialize()
      super()

      if File.exist?(::SELECTIONS)
        JSON.parse(File.read(::SELECTIONS)).each do |selection|
          add_button(selection["name"]) do
            File.open("/run/boot/choice", "w") do |file|
              file.write(selection["id"])
            end

            # Put back the console on the framebuffer
            VTConsole.map_console(1)
            exit 0
          end
        end
      else
        LVGL::LVLabel.new(@container).tap do |label|
          text = "No generations could be found.\n\n"

          if LVGL::Introspection.simulator?
            text += "This is normal in the simulator."
          else
            text += "This is anormal, and may be a sign of things being wrong."
          end

          label.set_long_mode(LVGL::LABEL_LONG::BREAK)
          label.set_text(text)
          label.set_align(LVGL::LABEL_ALIGN::CENTER)
          label.set_width(@container.get_width_fit)
        end
      end
    end
  end
end

# We need to start somewhere...
BootGUI::MainWindow.instance.present

# And keep the GUI active.
LVGUI.main_loop
