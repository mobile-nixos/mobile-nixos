module GUI; end

# A grid of characters, just good enough to run a tmux pane into
# through TmuxPuppeteer.
class GUI::TerminalPuppet < LVGUI::Widget
  attr_reader :terminal_width
  attr_reader :terminal_height
  attr_accessor :command
  attr_reader :puppet
  attr_accessor :logging_identifier

  CELL_CHAR = "#"

  def initialize(parent)
    super(LVGL::LVContainer.new(parent))

    @logging_identifier = nil
    @terminal_height = 30
    @terminal_width = 1
    @command = nil

    # Setup the container
    set_layout(LVGL::LAYOUT::COL_M)
    set_fit2(LVGL::FIT::FILL, LVGL::FIT::TIGHT)
    get_style(LVGL::CONT_STYLE::MAIN).dup.tap do |style|
      set_style(LVGL::CONT_STYLE::MAIN, style)
      style.body_main_color = 0xFF000000
      style.body_grad_color = 0xFF000000
      style.body_border_color = 0xFFFFFFFF
      style.body_border_width = LVGUI.pixel_scale(2)

      padding = LVGUI.pixel_scale(12)
      style.body_padding_top = padding
      style.body_padding_left = padding
      style.body_padding_right = padding
      style.body_padding_bottom = padding
      style.body_opa = LVGL::OPA::HALF
      #style.body_padding_inner = 0
    end
    
    # Add the cursor *under* the text (for now)
    # TODO: attach a text label to the cursor to render the char
    #       in reverse color (e.g. black on white)
    @cursor = LVGL::LVContainer.new(self)
    @cursor.set_protect(LVGL::PROTECT::POS)

    # Add the label
    @text = LVGL::LVLabel.new(self)

    @text.get_style(LVGL::LABEL_STYLE::MAIN).dup().tap do |style|
      @text.set_style(LVGL::LABEL_STYLE::MAIN, style)
      style.text_font = LVGUI::Fonts.monospace(16)
      style.text_color = 0xFFFFFFFF
    end

    # Assuming the font size is never changed.
    # This is the last moment before we set the label width, so
    # the last moment we can get the size of a cell.
    @text.set_text(CELL_CHAR)
    @cell_width  = @text.get_width()
    @cell_height = @text.get_height()

    # Get the "line height" by seeing what's the proportion
    # taken by the first line and the gap.
    @text.set_text([CELL_CHAR, CELL_CHAR].join("\n"))
    @line_height = (@text.get_height() - @cell_height).to_f / @cell_height

    @text.set_long_mode(LVGL::LABEL_LONG::BREAK)
    @text.set_align(LVGL::LABEL_ALIGN::LEFT)
    @text.set_width(parent.get_width_fit())

    @text.set_text("")

    @cursor.set_height(@cell_height)
    @cursor.set_width(@cell_width)

    LVGL::LVStyle::STYLE_TRANSP.dup.tap do |style|
      @cursor.set_style(LVGL::CONT_STYLE::MAIN, style)
      style.body_border_width   = 0
      style.body_padding_top    = 0
      style.body_padding_bottom = 0
      style.body_padding_left   = 0
      style.body_padding_right  = 0
      style.body_main_color = 0xFF_FFFFFF
      style.body_grad_color = style.body_main_color
      style.body_opa = (0.75*255).to_i
    end

    refresh_terminal_size()
  end

  def refresh_terminal_size()
    @text.set_text(CELL_CHAR)

    i = 1
    while @text.get_height() == @cell_height or i > 100
      i += 1
      @text.set_text(CELL_CHAR*i)
    end

    @terminal_width = i-1
    @text.set_text("")
  end

  # Must be called to *start* the process in the terminal.
  def run()
    raise "TerminalPuppet needs a command to run." unless @command

    @puppet = TmuxPuppeteer.new(
      @command,
      width: terminal_width,
      height: terminal_height,
      logging_identifier: @logging_identifier,
    )
  end

  def terminal_height=(val)
    @terminal_height = val
    update_terminal()
  end

  def terminal_width=(val)
    @terminal_width = val
    update_terminal()
  end

  def update_terminal()
    if @puppet
      @puppet.resize_window("-x#{terminal_width}", "-y#{terminal_height}")
      text = @puppet.capture_pane().strip()
      # Pad lines, or else the terminal will not be at its full height.
      text += "\n" * (@terminal_height - text.lines.count)
      @text.set_text(text)

      x, y, shown = @puppet.cursor_position
      @cursor.set_x(@cell_width * (x) + @text.get_x())
      @cursor.set_y(@cell_height*@line_height * (y) + @text.get_y())
      @cursor.set_hidden(!shown)
    end
  end

  # Must be called to cull stray tmux sessions
  def cleanup()
    if @puppet
      @puppet.kill_server()
    end
  end

  def pane_dead?()
    if @puppet
      @puppet.pane_dead?
    else
      # Did not run yet, so not dead yet.
      false
    end
  end

  def pane_dead_status()
    if @puppet
      @puppet.pane_dead_status
    else
      # Did not run yet, so not dead yet.
      nil
    end
  end
end
