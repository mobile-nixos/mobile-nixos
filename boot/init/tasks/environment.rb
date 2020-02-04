# Loads a basic environment.
# This is used mainly to make LD_LIBRARY_PATH valid, and additionally points
# PATH to extraUtils.
class Tasks::Environment < SingletonTask
  def initialize()
    # Make the Environment target depend on this task.
    Targets[:Environment].add_dependency(:Task, self)
  end

  def run()
    # Assumes this is *already* symlinked in the initrd.
    # This is a sane assumption as running executables will fail without this.
    UDev.simple_load_environment("/etc/udev/rules.d/00-env.rules")
  end
end
