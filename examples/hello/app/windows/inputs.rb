module GUI
  class InputsWindow < BaseLogWindow
    COMMAND = "lsinput"

    def initialize()
      super(explanation: "Output of #{COMMAND}")
    end

    def on_present()
      set_text(`#{COMMAND} 2>&1`)
    end
  end
end
