module System::ConfigFSUSB
  CONFIGFS     = "/sys/kernel/config"
  CONFIGFS_USB = File.join(CONFIGFS, "usb_gadget")

  module Quirks
    def self.gsi_rndis(function_dir)
      # Activate the IPA stuff... ugh.
      System.write("/dev/ipa", 1)
    end

    def self.mass_storage_0(function_dir)
      device = Configuration["storage"]["internal"]
      System.write(File.join(function_dir, "lun.0/file"), device)
    end
  end

  module FunctionFS
    ROOT = "/dev/usb-ffs"

    class FFSDaemon
      def start()
        raise "#start() needs to be set on #{self.class.name}"
      end
    end

    module Daemon
    end

    class Daemon::Adb < FFSDaemon
      def self.start()
        System.spawn("adbd")
        # `adbd` is not ready instantly. We need *some* time to pass for it
        # to start and be ready.
        sleep(1)
      end
    end

    DAEMONS = {
      adb: Daemon::Adb
    }

    def self.mount(feature_name)
      target = File.join(ROOT, feature_name)
      FileUtils.mkdir_p(target)
      System.mount(feature_name, target, type: "functionfs")
    end
    
    def self.umount(feature_name)
      target = File.join(ROOT, feature_name)
      System.umount(target)
      Dir.delete(target)
    end

    def self.start_daemon(feature_name)
      feature_name = feature_name.to_sym()
      $logger.debug("FunctionFS.start_daemon(#{feature_name.inspect}) // #{feature_name.inspect}")
      if DAEMONS[feature_name]
        DAEMONS[feature_name].start()
      else
        $logger.fatal("Tried to get FunctionFS Daemon for #{feature_name} (#{feature_name.constantize()}) and failed.")
      end
    end
  end 

  # This is a bit underdocumented in the configfs and gadgetfs docs, but this
  # would be used to translate strings in multiple languages.
  # In practice, it never happens and is hardcoded to en-US.
  # https://docs.microsoft.com/en-us/windows/win32/intl/language-identifier-constants-and-strings
  # https://docs.microsoft.com/en-us/windows/win32/msi/localizing-the-error-and-actiontext-tables
  # Yes, the language identifiers are the Microsoft ones. I haven't found a
  # detailed explanation for this, but it's part of the USB spec.
  STRINGS_SUFFIX = "strings/0x409" # en-US ¯\_(ツ)_/¯

  # https://www.kernel.org/doc/Documentation/usb/gadget_configfs.txt
  class Gadget
    attr_reader :name
    attr_accessor :features

    def needs_ffs?()
      Configuration["boot"]["usb"]["functions"].each do |feature, function_name|
        return true if function_name.match(/^ffs\./)
      end
    end

    # Initializes a USB gadget
    # The name is actually arbitrary, but it is customary to use `gn` where n
    # is an incrementing number.
    def initialize(name)
      @name = name
    end

    def path_prefix()
      File.join(CONFIGFS_USB, name)
    end

    def id_vendor=(value)
      set_id("idVendor", value)
    end

    def id_product=(value)
      set_id("idProduct", value)
    end

    def manufacturer=(value)
      set_string("manufacturer", value)
    end

    def product=(value)
      set_string("product", value)
    end

    def serial_number=(value)
      set_string("serialnumber", value)
    end

    def set_id(kind, value)
      value = ["0", value.sub(/^0x/, "")].join("x")
      System.write(File.join(path_prefix, kind), value)
    end

    def set_string(name, value)
      System.write(File.join(path_prefix, STRINGS_SUFFIX, name), value)
    end

    def prepare()
      FileUtils.mkdir_p(File.join(path_prefix, STRINGS_SUFFIX))
    end

    def activate!()
      # TODO: explore more than one "config" in a gadget. (c.1)
      # First, "document" features.
      config_dir = File.join(path_prefix, "configs/c.1")
      FileUtils.mkdir_p(File.join(config_dir, STRINGS_SUFFIX))
      System.write(File.join(config_dir, STRINGS_SUFFIX, "configuration"), features.join(","))

      # Then activate features.
      features.each do |feature|
        # We're using a "feature name -> function name" mapping to make a better
        # end-user UX. They don't care *how* rndis is enabled, only that rndis
        # has to be enabled.
        # Though here we need to know *how* to enable e.g. rndis.
        # This is why `function_name` exists, it's the gadgetfs function name
        # for the required "logical" feature.
        function_name = Configuration["boot"]["usb"]["functions"][feature]
        function_dir = File.join(path_prefix, "functions", function_name)
        feature_dir = File.join(config_dir, feature)
        FileUtils.mkdir_p(function_dir)
        System.symlink(function_dir, feature_dir)

        # Handle FunctionFS
        if function_name.match(/^ffs\./)
          $logger.debug("Handling FunctionFS feature: #{feature} with function name: #{function_name}")
          FunctionFS.mount(feature)
          FunctionFS.start_daemon(feature)
        end

        quirk_name = function_name.gsub(/\./, "_").to_sym
        $logger.debug("Looking for quirk: #{quirk_name}")
        Quirks.send(quirk_name, function_dir) if Quirks.respond_to?(quirk_name)
      end

      # Then, attach to the USB driver.
      if features.length > 0 then
        # Equivalent to:
        # (cd /sys/class/udc; echo *) > g1/UDC
        # The idea is to give a controller name taken from the filesystem.
        System.write(
          File.join(path_prefix, "UDC"),
          Dir.children("/sys/class/udc").first
        )
      end
    end

    # Tears down just enough so that a `kexec` call is successful.
    def teardown()
      # See 6. Disabling the gadget
      # ~ equiv to: echo "" > UDC
      System.write(File.join(path_prefix, "UDC"), "\n")
      sleep(0.1)

      # See 7. Cleaning up
      System.delete(*Dir.glob(File.join(path_prefix, "configs/*/*")))
      System.delete(*Dir.glob(File.join(path_prefix, "configs/*/strings/*")))
      System.delete(*Dir.glob(File.join(path_prefix, "configs/*")))
      System.delete(*Dir.glob(File.join(path_prefix, "functions/*")))
      System.delete(*Dir.glob(File.join(path_prefix, "strings/*")))
      System.delete(path_prefix)
    end
  end
end

class System::AndroidUSB
  include Singleton
  attr_accessor :features
  attr_accessor :id_vendor, :id_product

  ANDROID_USB  = "/sys/class/android_usb"
  ALIASES_PATH = "#{ANDROID_USB}/android0/f_ffs/aliases"

  def needs_ffs?()
    # TODO: add other known ffs android_usb features
    Configuration["boot"]["usb"]["features"].any?("adb")
  end

  def path_prefix()
    File.join(ANDROID_USB, "android0")
  end

  def manufacturer=(value)
    set_string("iManufacturer", value)
  end

  def product=(value)
    set_string("iProduct", value)
  end

  def serial_number=(value)
    set_string("iSerial", value)
  end

  def set_id(kind, value)
    value = value.sub(/^0x/, "")
    System.write(File.join(path_prefix, kind), value)
  end

  def set_string(name, value)
    System.write(File.join(path_prefix, name), value)
  end

  def prepare()
  end

  def activate!()
    # Ensure it is not enabled
    System.write(File.join(path_prefix, "enable"), "0")

    # TODO: decouple FFS features
    # Start the FFS endpoint, if needed
    if @features.any?("adb")
      System.write(ALIASES_PATH, "adb")
      System::ConfigFSUSB::FunctionFS.mount("adb")
    end

    set_id("idVendor", @id_vendor)
    set_id("idProduct", @id_product)
    System.write(File.join(path_prefix, "bDeviceClass"), "0")
    System.write(File.join(path_prefix, "bDeviceSubClass"), "0")
    System.write(File.join(path_prefix, "bDeviceProtocol"), "0")
    System.write(File.join(path_prefix, "functions"), @features.join(","))

    sleep(0.1)
    System.write(File.join(path_prefix, "enable"), "1")
    sleep(0.1)

    # Confusingly enough, this needs to be started *after* enabling the device
    # for android_usb
    # Start the adbd daemon for the FFS endpoint
    if @features.any?("adb")
      System::ConfigFSUSB::FunctionFS.start_daemon("adb")
    end
  end

  def teardown()
    # no-op
  end
end

# This task detects which gadget mode to use, and sets it up.
class Tasks::SetupGadgetMode < SingletonTask
  def initialize()
    add_dependency(:Mount, "/sys")
    add_dependency(:Mount, System::ConfigFSUSB::CONFIGFS) if mode == "gadgetfs"
    # If there's a `/vendor` mount point, it's likely that it's highly possible
    # that it's going to be required for firmwares.
    if Configuration["nixos"]["boot"]["specialFileSystems"]["/vendor"]
      add_dependency(:Mount, "/vendor")
    end
    Targets[:SwitchRoot].add_dependency(:Task, self)

    # TODO: Decouple dependencies from features.
    if Configuration["boot"]["usb"]["features"].any?("mass_storage")
      add_dependency(:Files, Configuration["storage"]["internal"])
    end

    if needs_ffs?
      add_dependency(:Mount, "/dev")
    end
  end

  # Whether the configuration needs FunctionFS
  def needs_ffs?()
    gadget.needs_ffs?()
  end

  def mode()
    Configuration["usb"]["mode"]
  end

  def gadget()
    @gadget ||= 
      case mode
      when "gadgetfs"
        log("Using CONFIGFS USB Gadget.")
        System::ConfigFSUSB::Gadget.new("g1")
      when "android_usb"
        log("Using ANDROID_USB Gadget.")
        System::AndroidUSB.instance()
      else
        log("No way to configure USB Gadget found.")
        return
      end
  end

  def run()
    return unless gadget

    log("Configuring USB Gadget.")
    gadget.prepare
    gadget.id_vendor = Configuration["usb"]["idVendor"]
    gadget.id_product = Configuration["usb"]["idProduct"]
    gadget.product = Configuration["device"]["name"]
    # FIXME : could this cause issues?
    gadget.manufacturer = "Mobile NixOS"
    gadget.serial_number = "0123456789"
    gadget.features = Configuration["boot"]["usb"]["features"]
    gadget.activate!
  end

  def teardown()
    return unless gadget
    gadget.teardown()
  end
end
