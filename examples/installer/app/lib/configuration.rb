# "Broker" for the configuration data.
# This somewhat decouples the installation bits from the internal structure,
# even though in the end we're relying on the internal structure from the steps
# windows.
module Configuration
  extend self

  DESCRIPTION = [
    { path: [ :fde, :enable ],                    label: "FDE enabled" },
    { path: [ :info, :fullname ],                 label: "Full name" },
    { path: [ :info, :username ],                 label: "User name" },
    { path: [ :info, :hostname ],                 label: "Host name" },
    { path: [ :environment, :phone_environment ], label: "Phone environment", mapping: ->(v) do GUI::PhoneEnvironmentConfigurationWindow::ENVIRONMENTS.to_h[v] end },
  ]

  def configuration_data
    GUI::SystemConfigurationStepsWindow.instance.configuration_data
  end

  def save_json!(path)
    File.write(path, configuration_data.to_json())
  end

  def configuration_description
    data = configuration_data
    DESCRIPTION.map do |description|
      value = data.dig(*description[:path])

      value = "yes" if value == true
      value = "no" if value == false
      if description[:mapping] then
        value = description[:mapping].call(value)
      end

      " - #{description[:label]}: #{value.inspect}"
    end
      .join("\n")
  end
end
