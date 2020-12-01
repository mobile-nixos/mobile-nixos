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

  def initialize(source, mapper)
    @source = source
    @mapper = mapper

    add_dependency(:Task, Tasks::UDev.instance)
    add_dependency(:Devices, source)
    add_dependency(:Mount, "/run")
    add_dependency(:Target, :Environment)
    self.class.register(@mapper, self)
  end

  def run()
    FileUtils.mkdir_p("/run/cryptsetup")

    TRIES.times do
      passphrase = Progress.ask("Passphrase for #{mapper}")

      begin
        Progress.exec_with_message("Checking...") do
          # TODO: implement with process redirection rather than shelling out
          System.run("echo #{passphrase.shellescape} | exec cryptsetup luksOpen #{source.shellescape} #{mapper.shellescape}")
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
