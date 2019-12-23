# Namespace where tasks can be defined, and hosting methods harmonizing a run.
module Tasks
  # Register a singleton task to be instantiated and ran.
  # @internal
  def self.register_singleton(klass)
    $logger.debug("Task #{klass.name} registered...")
    @singletons_to_be_instantiated ||= []
    @singletons_to_be_instantiated << klass
  end

  # Register one task to be ran.
  def self.register(task)
    $logger.debug("Task #{task.name} registered...")
    @tasks ||= []
    @tasks << task
  end

  # Tries to run *all* tasks.
  def self.go()
    # Registers tasks that still needs to be instantiated
    @singletons_to_be_instantiated.each do |klass|
      register(klass.instance)
    end
    @singletons_to_be_instantiated = []

    until @tasks.all?(&:ran) do
      @tasks
        .reject(&:ran)
        .each do |task|
          task._try_run_task
        end
      # Don't burn the CPU
      sleep(0.1)
    end
  end
end

# Basic task class.
class Task
  attr_reader :ran

  def self.new(*args)
    $logger.debug("New instance of #{self.name}...")
    $logger.debug(" -> #{args.inspect}")
    instance = super(*args)
    Tasks.register(instance)
    instance
  end

  def name
    self.class.name
  end

  def self.inherited(subclass)
    $logger.debug("#{subclass.name} created...")
  end

  def add_dependency(kind, *args)
    dependencies << Dependencies.const_get(kind.to_sym).new(*args)
  end

  def dependencies_fulfilled()
    dependencies.all?(&:fulfilled)
  end

  # Internal actual way to run the task
  # This runs the `#run` method.
  def _try_run_task()
    $logger.debug("Looking to run task #{name}...")
    return unless dependencies_fulfilled
    unless @ran
      $logger.info("Running #{name}...")
      run()
      $logger.info("Finished #{name}...")
      @ran = true
    end
  end

  def dependencies()
    @dependencies ||= []
    @dependencies
  end
end

# A task that can only have one instance.
class SingletonTask < Task
  include Singleton

  def self.inherited(subclass)
    super
    # Delay initializing, as right now we have an fresh new empty class.
    Tasks.register_singleton(subclass)
  end
end
