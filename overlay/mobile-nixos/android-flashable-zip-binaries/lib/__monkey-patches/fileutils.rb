# https://github.com/ruby/ruby/blob/ruby_2_7/lib/fileutils.rb
module FileUtils
  extend self

  def mkdir_p(*dirs)
    dirs.each do |dir|
      $logger.debug(" $ mkdir -p #{dir}")
      # Create all paths in the given hierarchy
      dir.split("/").reduce("") do |component, acc|
        dir = [component, acc].join("/")
        Dir.mkdir(dir) unless Dir.exist?(dir)
        dir
      end
    end
  end

  def remove_entry(path)
    stat = File.stat(path)
    return File.delete(path) unless stat.directory?
    Dir.entries(path).each do |p|
      next if [".", ".."].include?(p)
      remove_entry(File.join(path, p))
    end
    Dir.delete(path)
  end
end
