# Use this task to define a "well-known" task that can be depended upon to stop
# execution until multiple tasks have been fulfilled.
#
# An example is to make a Target that depends on all mount points needed for
# booting the system, and the task that boots depend on that target.
#
# This removes the need of the final tasks depending on the target to need to
# know about the dependencies.
#
# Prefer actually depending on discrete tasks rather than targets. Use targets
# only to describe a vague step that may be fulfilled by different
# implementations.
class Tasks::Target < Task
  def initialize(name)
    @name = name.to_sym
  end

  def run(); end

  def name()
    "#{super}<#{@name}>"
  end
end

module Targets
  def self.[](name)
    name = name.to_sym
    @targets ||= {}
    @targets[name] = Tasks::Target.new(name) unless @targets[name]
    @targets[name]
  end
end
