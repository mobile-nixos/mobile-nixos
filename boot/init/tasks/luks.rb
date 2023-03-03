# Opens LUKS devices
class Tasks::Luks < Task
  attr_reader :source
  attr_reader :mapper

  TRIES = 10

  class ExistingLuksTask < StandardError
  end

  class CouldNotUnlock < StandardError
  end

  def self.register(mapper, instance)
    @registry ||= {}
    unless @registry[mapper].nil? then
      raise ExistingLuksTask.new("LUKS task for '#{mapper}' already exists.")
    end
    @registry[mapper] = instance
  end

  def self.registry()
    @registry
  end

  def initialize(source, mapper, info)
    @source = source
    @mapper = mapper

    # Current known and used keys
    #    "device", # First param, source
    #    "allowDiscards",
    #    "bypassWorkqueues",
    #
    # Current known and unused (by design) keys
    #    "fallbackToPassword", # Nothing else than password
    #
    # Currently known unsupported keys (contributions welcome)
    #    "crypttabExtraOpts",
    #    "fido2",
    #    "header",
    #    "gpgCard",
    #    "keyFile",
    #    "keyFileOffset",
    #    "keyFileSize",
    #    "postOpenCommands",
    #    "preLVM",
    #    "preOpenCommands",
    #    "yubikey",
    @info = info
    @cryptsetup_args = []
    if @info["allowDiscards"]
      @cryptsetup_args.concat [
        "--allow-discards",
      ]
    end
    if @info["bypassWorkqueues"] then
      @cryptsetup_args.concat [
        "--perf-no_read_workqueue",
        "--perf-no_write_workqueue",
      ]
    end

    add_dependency(:Task, Tasks::UDev.instance)
    add_dependency(:Devices, source)
    add_dependency(:Mount, "/run")
    add_dependency(:Target, :Environment)
    # Or else we can't get the passphrase!!
    # TODO: instead of depending on the Splash Task, depend on a new type of
    #       dependency describing a "user input", which would be provided on
    #       the "message bus"
    #       e.g. `add_dependency(:Ask, :passphrase, "Passphrase for #{mapper}")`
    add_dependency(:Task, Tasks::Splash.instance)
    self.class.register(@mapper, self)
  end

  def run()
    FileUtils.mkdir_p("/run/cryptsetup")

    TRIES.times do
      passphrase = Progress.ask("Passphrase for #{mapper}")

      begin
        Progress.exec_with_message("Checking...") do
          args = [
            "luksOpen",
            source,
            mapper,
            *@cryptsetup_args,
          ]
          # TODO: implement with process redirection rather than shelling out
          System.run("echo #{passphrase.shellescape} | exec cryptsetup #{args.shelljoin}")
        end
        Progress.update({label: nil})

        # If we're there, we're done!
        return
      rescue System::CommandError
        Progress.update({label: "Wrong passphrase given..."})
      end
    end

    # We failed multiple times.
    System.failure("CRYPTSETUP_FAILED_UNLOCK", "Failed to unlock", "Could not unlock #{source}.\n\nTried #{TRIES} times.", color: "000000", delay: 60)
  end

  def name()
    "#{super}(#{source}, #{mapper})"
  end
end
