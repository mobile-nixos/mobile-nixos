class Dir
  def self.children(dirname)
    acc = []
    Dir.open(dirname) do |dir|
      dir.each do |child|
        next if child == "." or child == ".."
        acc << child
      end
    end
    acc
  end
end
