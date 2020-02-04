# Creates full directory path
class Tasks::Directory < Task
  def initialize(path)
    @path = path
  end

  def run()
    FileUtils.mkdir_p(@path)
  end

  def name()
    "#{super}(#{@path})"
  end
end
