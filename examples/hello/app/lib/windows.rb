module GUI
  # Helper methods to help creating a "button palette" kind of window.
  module ButtonPalette
    def add_button(label)
      Button.new(@container).tap do |btn|
        btn.glue_obj(true)
        btn.set_label(label)
        btn.event_handler = ->(event) do
          case event
          when LVGL::EVENT::CLICKED
            yield
          end
        end
      end
    end

    def add_buttons(list)
      list.each do |pair|
        label, action = pair
        add_button(label, &action)
      end
    end
  end
end
