module Installer
  extend self

  def run_script(name)
    script = File.join(Dir.pwd, name)

    Edify.ui_print(":: Extracting #{name}")
    Zip.extract(name)

    if File.exist?(script)
      Edify.ui_print(":: Running #{name}")
      if block_given?
        eval(yield(File.read(script)))
      else
        eval(File.read(script))
      end
    else
      Edify.ui_print("ERROR: Could not find #{name} in zip file.")
      Edify.ui_print("Aborting Mobile NixOS Flashable Zip...")
    end
  end
end
