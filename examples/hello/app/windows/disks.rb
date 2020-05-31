module GUI
  class DisksWindow < BaseLogWindow
    COMMAND = "lsblk --list -o NAME,SIZE,TYPE,PARTLABEL"

    def initialize()
      super(explanation: "Output of #{COMMAND}")
    end

    def on_present()
      set_text(`#{COMMAND}`)
    end
  end
end
