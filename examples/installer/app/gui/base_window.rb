module GUI; end
class GUI::BaseWindow < LVGUI::BaseWindow
  attr_reader :header_bar

  def run(*cmd)
    $stderr.puts " $ " + cmd.join(" ")
    system(*cmd)
  end

  def on_initialization_finished()
    @header_bar.refresh_sizes()
  end

  def on_header_init()
    @header_bar = MobileNixOS::EnhancedHeaderBar.new(@screen)
    @header_bar.set_label("Installer")
  end

  def present()
    unless self.class == GUI::QuitWindow
      GUI::QuitWindow.instance.back_location = self
    end
    super()
  end
end
