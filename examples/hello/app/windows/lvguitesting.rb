module GUI
  class LVGUITestingWindow < LVGUI::BaseWindow
    include LVGUI::BaseUIElements
    include LVGUI::ButtonPalette
    include LVGUI::Window::WithBackButton
    goes_back_to ->() { MainWindow.instance }

    def initialize()
      super()

      add_main_text(%Q{The different UI toolkit controls are shown here.\n\nThis is used to validate UI behaviour on different platforms.\n\n})

      # Add a toggle switch
      @switch = add_switch(
        "Toggle switch",
        description: "This label will mirror its value in the description field after the first activation.",
        initial: true,
      ) do |new_state|
        @switch.set_description(new_state.inspect)
      end
    end
  end
end
