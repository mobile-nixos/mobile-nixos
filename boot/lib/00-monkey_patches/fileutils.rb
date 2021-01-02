class FileUtils
  def self.mkdir_p(*dirs)
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
end
