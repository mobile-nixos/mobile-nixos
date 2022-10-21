class FileUtils
  def self.cp_r(src, dest)
    system("cp", "-r", src, dest)
  end

  def self.mkdir_p(*dirs)
    dirs.each do |dir|
      # Create all paths in the given hierarchy
      dir.split("/").reduce("") do |component, acc|
        dir = [component, acc].join("/")
        Dir.mkdir(dir) unless Dir.exist?(dir)
        dir
      end
    end
  end
end
