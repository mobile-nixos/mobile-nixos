module Zip
  extend self

  def extract(file)
    Busybox.unzip("-q", "-o", $zip_path, file).lines do |line|
      Edify.ui_print(line)
    end
  end
end
