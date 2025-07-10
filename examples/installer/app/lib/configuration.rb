module Configuration
  module Device
    extend self

    def device_uefi()
      arch = `uname -m`.strip
      ["uefi", arch].join("-")
    end

    def is_uefi()
      @is_uefi ||= File.exist?("/sys/firmware/efi")
      @is_uefi
    end

    # TODO: move device-specific detection into some form of generic data file.
    def identifier()
      # First let's short circuit for the simulator.
      # We need a good enough device name.
      if LVGL::Introspection.simulator?
        # Safe~ish assumption for the simulator.
        return device_uefi
      end

      # Then let's try with the device tree compatible.
      if File.exist?("/proc/device-tree/compatible") then
        # Let's take the most precise compatible name.
        compatible = File.read("/proc/device-tree/compatible").split("\0").first

        case compatible
        when /^pine64,pinephone-pro/
          return "pine64-pinephonepro"
        when /^pine64,pinephone/
          return "pine64-pinephone"
        when /^pine64,pinetab/
          return "pine64-pinetab"
        when /^google,juniper/
          return "acer-juniper"
        when /^google,krane/
          return "lenovo-krane"
        when /^google,lazor/
          return "acer-lazor"
        when /^google,wormdingler/
          return "lenovo-wormdingler"
        when /^google,scarlet/
          # TODO: detect the actual scarlet model...
          return "asus-dumo"
        end
      end

      # Uh, no device tree? no problem!
      # Let's try and detect the device with its DMI info
      if File.exist?("/sys/class/dmi/id/product_name")
        product_name = File.read("/sys/class/dmi/id/product_name")
        chassis_vendor = File.read("/sys/class/dmi/id/chassis_vendor")
        case chassis_vendor
        when /^QEMU$/
          return "qemu-uefi"
        end
      end

      # Oh, still nothing specific? Let's hope it's just generic UEFI!
      if is_uefi
        return device_uefi
      end

      # This shouldn't really happen. We won't produce builds without some way
      # to detect the device identifier.
      "... unknown device ..."
    end

    # TODO: move with the device detection into generic data-driven config.
    def system_type()
      case identifier
      when "pine64-pinephone", "pine64-pinetab", "pine64-pinephonepro"
        return "u-boot"
      when "acer-juniper", "acer-lazor", "lenovo-krane", "lenovo-wormdingler", "asus-dumo"
        return "depthcharge"
      end

      # Safe~ish default
      return "uefi" if is_uefi

      raise "Aborting: Unknown system type...."
    end

    # TODO: move with the device detection into generic data-driven config.
    def target_disk()
      if LVGL::Introspection.simulator?
        path = "./installer-bogus-disk.img"
        system("fallocate", "-l", "1G", path)
        return File.realpath(path)
      end

      path =
        case identifier
        when "pine64-pinephone", "pine64-pinetab"
          # Allwinner A64 eMMC
          File.join("/dev/disk/by-path", "platform-1c11000.mmc")
        when "asus-dumo", "pine64-pinephonepro"
          # RK3399 eMMC
          File.join("/dev/disk/by-path", "platform-fe330000.mmc")
        when "acer-juniper", "lenovo-krane"
          # MT8183 eMMC
          File.join("/dev/disk/by-path", "platform-11230000.mmc")
        when "acer-lazor", "lenovo-wormdingler"
          # Qualcomm 7c eMMC
          File.join("/dev/disk/by-path", "platform-7c4000.mmc")
        when "qemu-uefi"
          # QEMU using e.g. `./result -drive "file=target.img"` for a second drive.
          File.join("/dev/disk/by-id/", "ata-QEMU_HARDDISK_QM00002")
        end

      raise "Unknown target disk" unless path

      File.realpath(path)
    end

    def boot_partition()
      if LVGL::Introspection.simulator?
        path = "./installer-bogus-boot-partition.img"
        system("touch", path)
        return File.realpath(path)
      end

      # The assumption for now is the boot partition is always the first one.
      # This assumption may not be true in the future.
      # Maybe we'll need to handle the "partitioning plan" here instead of in the formatting script.
      Part.part(target_disk, 1)
    end
  end

  module Part
    extend self

    def part(disk, number)
      if disk.match(%r{^/dev/mmcblk}) then
        [disk, "p", number].join()
      elsif disk.match(%r{^/dev/sd[a-z]}) then
        [disk, number].join()
      else
        raise "Partition numbering scheme for this disk type (for '#{disk}') not implemented."
      end
    end
  end
end

# Configuration file for NixOS
class Configuration::NixOSConfiguration
  attr_reader :configuration

  def self.from_configuration(data)
    instance = self.new
    instance.instance_exec do
      @configuration = data
    end
    instance
  end

  def state_version()
    File.read("/etc/os-release").split("\n").grep(/^VERSION_ID=/).first.split("=").last.gsub('"', "")
  end

  def cpu_count()
    core_count = File.read("/proc/cpuinfo").split(/\n+/).grep(/^processor/).count
    # Why `/2`? Assume some big.LITTLE-ness, or even "low vs. high" cores.
    (core_count / 2).ceil
  end

  def luks_name(part)
    [
      "LUKS",
      @configuration[:info][:hostname].upcase.gsub(/[-_.]/, "-"),
      part.upcase,
    ].join("-")
  end

  def username()
    @configuration[:info][:username]
  end

  def hashed_password()
    return @hashed_password if @hashed_password
    password = @configuration[:info][:password]
    # FIXME insecure; Open3 should be preferred
    # but we're well on the other side of the airtight hatchway.
    # The info leak in the process list would imply much more dire consequences in a temporary installer system.
    @hashed_password = `echo -n #{password.shellescape} | mkpasswd --stdin --method=sha-512`.chomp
    @hashed_password
  end

  def imports_fragment()
    imports = [
      "(import <mobile-nixos/lib/configuration.nix> { device = #{Configuration::Device.identifier.to_json}; })",
      "./hardware-configuration.nix",
    ]

    case @configuration[:environment][:phone_environment].to_sym
    when :phosh
      imports << "<mobile-nixos/examples/phosh/phosh.nix>"
    when :plamo
      imports << "<mobile-nixos/examples/plasma-mobile/plasma-mobile.nix>"
    end

    imports = imports.join("\n").indent
<<EOF
imports = [
#{imports}
];
EOF
  end

  def system_fragment()
<<EOF
networking.hostName = #{@configuration[:info][:hostname].to_json};
EOF
  end

  def defaults_fragment()
<<EOF
#
# Opinionated defaults
#

# Use Network Manager
networking.wireless.enable = false;
networking.networkmanager.enable = true;

# Use PipeWire
services.pipewire.enable = true;

# Enable Bluetooth
hardware.bluetooth.enable = true;

# Bluetooth audio
services.pulseaudio.package = pkgs.pulseaudioFull;

# Enable power management options
powerManagement.enable = true;

# It's recommended to keep enabled on these constrained devices
zramSwap.enable = true;
EOF
  end

  def phone_environment_fragment()
    # We are importing the `examples/#{environment}/#{environment}.nix`
    # file already. This ensures the demo systems don't deviate from
    # the opinionated configuration.
    #
    # Only add system-specific config for the environment here.
    # e.g. things that are configured in the installer like the
    # login name for the user.
    case @configuration[:environment][:phone_environment].to_sym
    when :phosh
<<EOF
# Auto-login for phosh
services.xserver.desktopManager.phosh = {
  user = #{username.to_json};
};
EOF
    when :plamo
<<EOF
# Auto-login for Plasma Mobile
services.displayManager.autoLogin = {
  user = #{username.to_json};
};
EOF
    end
  end

  def user_fragment()
<<EOF
#
# User configuration
#

users.users.#{username.to_json} = {
  isNormalUser = true;
  description = #{@configuration[:info][:fullname].to_json};
  hashedPassword = #{hashed_password.to_json};
  extraGroups = [
    "dialout"
    "feedbackd"
    "networkmanager"
    "video"
    "wheel"
  ];
};
EOF
  end

  def tail_fragment()
<<EOF
# This value determines the NixOS release from which the default
# settings for stateful data, like file locations and database versions
# on your system were taken. It‘s perfectly fine and recommended to leave
# this value at the release version of the first install of this system.
# Before changing this value read the documentation for this option
# (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
system.stateVersion = "#{state_version}"; # Did you read the comment?
EOF
  end

  def configuration_nix()
    fragments = [
      imports_fragment,
      system_fragment,
      defaults_fragment,
      phone_environment_fragment,
      user_fragment,
      tail_fragment,
    ]

<<EOF
{ config, lib, pkgs, ... }:

{
#{fragments.map(&:indent).join("\n\n")}
}
EOF
  end

  def filesystems_fragment()
    fragments = [
<<EOF
fileSystems = {
  "/" = {
    device = "/dev/disk/by-uuid/#{@configuration[:filesystems][:rootfs][:uuid]}";
    fsType = "ext4";
  };
};
EOF
    ]
    if @configuration[:fde][:enable] then
fragments << <<EOF
boot.initrd.luks.devices = {
  #{luks_name("rootfs").to_json} = {
    device = "/dev/disk/by-uuid/#{@configuration[:filesystems][:luks][:uuid]}";
  };
};
EOF
    end

    fragments.join("\n")
  end

  def hardware_configuration_nix()
<<EOF
# NOTE: this file was generated by the Mobile NixOS installer.
{ config, lib, pkgs, ... }:

{
#{filesystems_fragment.indent}

  nix.settings.max-jobs = lib.mkDefault #{cpu_count.to_json};
}
EOF
  end

  private

  def initialize()
  end
end

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

  def luks_uuid()
    @luks_uuid ||= SecureRandom.uuid
  end

  def rootfs_uuid()
    @rootfs_uuid ||= SecureRandom.uuid
  end

  def label_for(part, prefix_length: 999)
    [
      raw_config[:info][:hostname].upcase.gsub(/[-_.]/, "_")[0..(prefix_length-1)],
      part.upcase,
    ].join("_")
  end

  # What's this?
  #
  # This is to make generation of the config easier.
  # Instead of relying on the intrinsic new UUID generated by e.g. mkfs.ext4
  # or crypsetup luksFormat, we provide the UUID, so we don't need to sniff
  # around for the UUID.
  #
  # There is no drawback in doing this.
  def filesystems_data()
    {
      luks: {
        # no label in LUKS v1
        uuid: luks_uuid,
      },
      rootfs: {
        # ext4 labels are 16 chars; 11 + "_ROOT"
        label: label_for("root", prefix_length: 11),
        uuid: rootfs_uuid,
      },
    }
  end

  def raw_config()
    GUI::SystemConfigurationStepsWindow.instance.configuration_data
  end

  def configuration_data
    raw_config.merge(
      {
        system_type: Configuration::Device.system_type,
        identifier: Configuration::Device.identifier,
        filesystems: filesystems_data,
      }
    )
  end

  def save_json!(path)
    File.write(path, configuration_data.to_json())
  end

  def save_configuration!(prefix)
    FileUtils.mkdir_p(prefix)
    File.write(
      File.join(prefix, "configuration.nix"),
      NixOSConfiguration.from_configuration(configuration_data).configuration_nix
    )
    File.write(
      File.join(prefix, "hardware-configuration.nix"),
      NixOSConfiguration.from_configuration(configuration_data).hardware_configuration_nix
    )
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
