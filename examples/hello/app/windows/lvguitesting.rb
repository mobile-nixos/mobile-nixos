module GUI
  class LVGUITestingWindow < LVGUI::BaseWindow
    include LVGUI::BaseUIElements
    include LVGUI::ButtonPalette
    include LVGUI::Window::WithBackButton
    goes_back_to ->() { MainWindow.instance }

    def initialize()
      super()

      add_main_text(%Q{The different UI toolkit controls are shown here.\n\nThis is used to validate UI behaviour on different platforms.\n})

      LVGUI::HorizontalSeparator.new(@container)

      add_main_text(%Q{\nThe description label here will mirror the switch's value.\n})

      add_textarea().tap do |ta|
        on_click = ->() do
          puts "clicked"
        end
        ta.on_submit = ->(value) do
          puts "submitted #{value.inspect}"
          puts " -> get_text: #{ta.get_text().inspect}"
        end
        ta.on_modified = ->(value) do
          puts "modified #{value.inspect}"
        end
      end

      add_textarea().tap do |ta|
        ta.set_pwd_mode(true)
        on_click = ->() do
          puts "clicked"
        end
        ta.on_submit = ->(value) do
          puts "submitted #{value.inspect}"
          puts " -> get_text: #{ta.get_text().inspect}"
        end
        ta.on_modified = ->(value) do
          puts "modified #{value.inspect}"
        end
      end

      # Add a toggle switch
      @switch = add_switch(
        "Toggle switch",
        description: "true",
        initial: true,
      ) do |new_state|
        @switch.set_description(new_state.inspect)
      end

      LVGUI::HorizontalSeparator.new(@container)

      add_main_text(%Q{\nThese items allow choosing among many options\n})

      @select = add_select("Options selection", [
        [:A, "Option A"],
        [:B, "Option B"],
        [:C, "Option C"],
        [:D, "Option D"],
        #[:_Z, "An option with a label that is large enough to cause a line wrap"],
        #[:_X, "Commas wrap snuggly,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,"],
      ]) do |new_state|
        p new_state
      end
    end
  end
end
