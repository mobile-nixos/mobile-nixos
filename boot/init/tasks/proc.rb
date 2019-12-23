# Runs a proc like a task.
# Useful to add some debugging commands depending on other tasks.
class Tasks::Proc < Task
  def initialize(p)
    @proc = p
  end

  def run()
    @proc.call
  end
end
