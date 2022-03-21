# Some hardware abstraction, specific to a particular use-case,
# but still must be generic enough.
#
# All of this must be implemented with the goal to produce a phone-oriented
# GUI toolkit.
module LVGUI::HAL
  # Provide battery information
  class Battery
    NODE_BASE = "/sys/class/power_supply"
    # Guesstimates the main battery for a list of likely candidates
    def self.main_battery()
      node = %w{
        battery
        bms
        BAT0
        *-battery
      }.map { |name| Dir.glob(File.join(NODE_BASE, name)).first }
        .compact
        .first

      if node
        Battery.new(node)
      else
        nil
      end
    end

    def initialize(node)
      @node = node
    end

    # google-walleye
    # [nixos@nixos:/sys/class/power_supply]$ cat battery/uevent 
    # POWER_SUPPLY_NAME=battery
    # POWER_SUPPLY_INPUT_SUSPEND=0
    # POWER_SUPPLY_STATUS=Charging
    # POWER_SUPPLY_HEALTH=Good
    # POWER_SUPPLY_PRESENT=1
    # POWER_SUPPLY_CHARGE_TYPE=Fast
    # POWER_SUPPLY_CAPACITY=56
    # POWER_SUPPLY_SYSTEM_TEMP_LEVEL=0
    # POWER_SUPPLY_CHARGER_TEMP=364
    # POWER_SUPPLY_CHARGER_TEMP_MAX=803
    # POWER_SUPPLY_INPUT_CURRENT_LIMITED=1
    # POWER_SUPPLY_VOLTAGE_NOW=3780507
    # POWER_SUPPLY_VOLTAGE_MAX=4400000
    # POWER_SUPPLY_VOLTAGE_QNOVO=-22
    # POWER_SUPPLY_CURRENT_NOW=183105
    # POWER_SUPPLY_CURRENT_QNOVO=-22
    # POWER_SUPPLY_CONSTANT_CHARGE_CURRENT_MAX=2700000
    # POWER_SUPPLY_TEMP=320
    # POWER_SUPPLY_TECHNOLOGY=Li-ion
    # POWER_SUPPLY_STEP_CHARGING_ENABLED=0
    # POWER_SUPPLY_STEP_CHARGING_STEP=-1
    # POWER_SUPPLY_CHARGE_DISABLE=0
    # POWER_SUPPLY_CHARGE_DONE=0
    # POWER_SUPPLY_PARALLEL_DISABLE=0
    # POWER_SUPPLY_SET_SHIP_MODE=0
    # POWER_SUPPLY_CHARGE_FULL=2805000
    # POWER_SUPPLY_DIE_HEALTH=Cool
    # POWER_SUPPLY_RERUN_AICL=0
    # POWER_SUPPLY_DP_DM=0
    # POWER_SUPPLY_CHARGE_COUNTER=1455951
    # POWER_SUPPLY_CYCLE_COUNT=849
    # POWER_SUPPLY_NAME=rk817-battery
    # POWER_SUPPLY_TYPE=Battery
    # POWER_SUPPLY_PRESENT=1
    # POWER_SUPPLY_STATUS=Discharging
    # POWER_SUPPLY_CHARGE_TYPE=N/A
    # POWER_SUPPLY_CHARGE_FULL=3801000
    # POWER_SUPPLY_CHARGE_FULL_DESIGN=4000000
    # POWER_SUPPLY_CHARGE_EMPTY_DESIGN=0
    # POWER_SUPPLY_CHARGE_NOW=3793632
    # POWER_SUPPLY_CONSTANT_CHARGE_VOLTAGE_MAX=4200000
    # POWER_SUPPLY_VOLTAGE_BOOT=4151670
    # POWER_SUPPLY_VOLTAGE_AVG=4117300
    # POWER_SUPPLY_VOLTAGE_OCV=16000
    # POWER_SUPPLY_CONSTANT_CHARGE_CURRENT_MAX=1500000
    # POWER_SUPPLY_CURRENT_BOOT=-39560
    # POWER_SUPPLY_CURRENT_AVG=-161508
    # POWER_SUPPLY_VOLTAGE_MIN_DESIGN=3500000
    # POWER_SUPPLY_VOLTAGE_MAX_DESIGN=4200000
    def uevent()
      File.read(File.join(@node, "uevent")).split("\n").map do |line|
        key, value = line.split("=", 2)
        [key.downcase.to_sym, value]
      end.to_h
    end

    def name()
      uevent[:power_supply_name] || "unknown"
    end

    def status()
      uevent[:power_supply_status] || "unknown"
    end

    def percent()
      if uevent[:power_supply_capacity]
        uevent[:power_supply_capacity].to_i
      elsif uevent[:power_supply_charge_now] and uevent[:power_supply_charge_full]
        (uevent[:power_supply_charge_now].to_f / uevent[:power_supply_charge_full].to_f * 100).round
      else
        "unknown"
      end
    end

    def charging?()
      status.downcase == "charging" || uevent[:power_supply_charge_done] == "1"
    end
  end
end
