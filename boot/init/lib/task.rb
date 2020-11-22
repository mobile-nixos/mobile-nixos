# Namespace where tasks can be defined, and hosting methods harmonizing a run.
module Tasks
  HUNG_BOOT_NOTIFICATION = 3 # seconds
  HUNG_BOOT_TIMEOUT = 60 # seconds

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
      # Their mere existence registers them.
      klass.instance
    end
    @singletons_to_be_instantiated = []

    # Sort tasks to reduce the amount of loops it needs to fulfill them all.
    # It's only a reduction due to files, mounts and devices being
    # unpredictable!
    @tasks.sort!

    hung_tasks_timer = Time.now

    until @tasks.all?(&:ran) do
      $logger.debug("=== Tasks resolution loop start ===")
      ran_one = false
      todo = @tasks
        .reject(&:ran)
        .tap do |tasks|
          $logger.debug("    Tasks order:")
          tasks.each do |t|
            $logger.debug("      - #{t}")
          end
        end

      # Update the current progress
      count = @tasks.length.to_f
      Progress.update({progress: (100 * (1 - (todo.length / count))).ceil})
      Progress.update({recovery: Hal::Recovery.wants_recovery?})

      todo.each do |task|
          if task._try_run_task then
            ran_one = true
            $logger.debug("#{task} ran.")
            break
          end
        end

      if ran_one
        # Reset the timer
        hung_tasks_timer = Time.now
        # And reset the hung state in the progress UI
        Progress.update({label: nil, hung: nil})
      else
        elapsed = Time.now - hung_tasks_timer
        $logger.debug("Time elapsed since something ran: #{elapsed}")

        # Any tasks, not currently depending on another task, that have yet
        # to be ran.
        # Serves nothing to point to tasks depending on other tasks.
        failed_tasks = todo.reject(&:depends_on_any_unfulfilled_task?)
        failed_dependencies = failed_tasks.map(&:dependencies).inject(:+).uniq

        if elapsed > HUNG_BOOT_NOTIFICATION
          label = "#{failed_tasks.length} tasks are waiting on #{failed_dependencies.length} unique dependencies.\n\n" +
            "(#{(HUNG_BOOT_TIMEOUT - elapsed).ceil} seconds left until boot is aborted.)"

          Progress.update({label: label, hung: elapsed})
        end

        if elapsed > HUNG_BOOT_TIMEOUT
          # Building this message is not pretty!
          msg =
            "#{failed_tasks.length} #{if failed_tasks.length == 1 then "task" else "tasks" end} " +
            "did not run within #{HUNG_BOOT_TIMEOUT} seconds.\n" +
            "\n" +
            "#{failed_dependencies.length} #{if failed_dependencies.length == 1 then "dependency" else "dependencies" end} " +
            "could not resolve:\n" +
            failed_dependencies.map(&:pretty_name).join("\n") +
            "\n"

          # Fail with a black backdrop, and force the message to stay up 60s
          System.failure("TASKS_HANG_TIMEOUT", "Hung Tasks", msg, color: "000000", delay: 60)
        end

        # Don't burn the CPU if we're waiting on something...
        $logger.debug("Sleeping")
        sleep(0.1)
      end
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

  # Sort first by dependencies, then by name, then by object_id
  # (for stable sort order)
  def <=>(other)
    return -1 if other.depends_on?(self)
    return  1 if depends_on?(other)

    by_ux_priority = ux_priority <=> other.ux_priority
    return by_ux_priority unless by_ux_priority == 0 

    by_name = name <=> other.name
    return by_name unless by_name == 0

    object_id <=> other.object_id
  end

  def depends_on?(other)
    dependencies.any? do |dependency|
      dependency.depends_on?(other)
    end
  end

  def add_dependency(kind, *args)
    raise NameError.new("No dependency named #{kind}") unless Dependencies.constants.include?(kind.to_sym)
    dependencies << Dependencies.const_get(kind.to_sym).new(*args)
  end

  def dependencies_fulfilled?()
    dependencies.all?(&:fulfilled?)
  end

  def depends_on_any_unfulfilled_task?()
    dependencies.reject(&:fulfilled?).any? do |dep|
      dep.is_a?(Dependencies::Task) or
      dep.is_a?(Dependencies::Target) 
    end
  end

  # Internal actual way to run the task
  # This runs the `#run` method.
  # Returns true when the task was ran.
  def _try_run_task()
    $logger.debug("Looking to run task #{name}...")
    return unless dependencies_fulfilled?
    unless @ran
      $logger.info("Running #{name}...")
      run()
      $logger.debug("Finished #{name}...")
      @ran = true
    end

    @ran
  end

  def dependencies()
    @dependencies ||= []
    @dependencies
  end

  # This allows a task to be ordered before other tasks, because it is used to
  # enhance the UX of the boot process. Assume this will be compared with +<=>+.
  # This should seldom be used, and mainly for tasks that show the progress of
  # the boot process.
  # (For internal use.)
  # @internal
  def ux_priority()
    0
  end

  # Same as name, but with the object_id appended.
  def to_s()
    name + "<0x#{object_id.to_s(16)}>"
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
