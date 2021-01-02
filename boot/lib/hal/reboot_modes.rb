module Hal
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
end
