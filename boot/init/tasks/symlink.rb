# Symlinks from source to target.
# Depends on target's `#dirname` existing.
class Tasks::Symlink < Task
  def initialize(source, target)
    @source = source
    @target = target
    # The actual source is not a dependency; the symlink can dangle freely.
    add_dependency(:Files, File.dirname(target))
  end

  def run()
    System.symlink(@source, @target)
  end

  def name()
    "#{super}(#{@source}, #{@target})"
  end
end
