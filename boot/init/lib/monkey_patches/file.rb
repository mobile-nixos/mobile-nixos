class File
  def self.write(filename, contents)
    File.open(filename, "w") do |file|
      file.write(contents)
    end
  end
end
