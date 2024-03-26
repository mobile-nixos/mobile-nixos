module LVGL::Hacks
  FONTS = {}
  @@assets_path = nil

  # +assets_path+ will be relative to an XDG data dir. E.g. /usr/share/
  def self.init(assets_path:)
    data_dir = [
      # First look in the `share` directory neighboring `libexec` where the
      # running mrb applet runs from.
      File.join(File.dirname(File.dirname($0)), "share"),
      # Then any XDG data dirs
      XDG.data_dirs,
    ]
      .flatten()
      .map { |dir| File.join(dir, assets_path) }
      .find { |dir| File.exists?(dir) }

    # Fallback to a probably non-existent dir
    # (So things don't crash too hard)
    data_dir ||= File.join(XDG.data_dirs.first, assets_path)
    LVGL::Hacks.set_assets_path(data_dir)

    LVGUI::Native.hal_init(get_asset_path(""))
    LVGUI::Native.lv_bmp_init()
    LVGUI::Native.lv_nanosvg_init()
  end

  def self.monitor_height=(v)
    if LVGL::Introspection.simulator?
      LVGUI::Native.monitor_height = v
    end
  end
  def self.monitor_width=(v)
    if LVGL::Introspection.simulator?
      LVGUI::Native.monitor_width = v
    end
  end
  def self.dpi()
      LVGUI::Native.mn_hal_default_dpi
  end
  def self.default_font()
      LVGUI::Native.mn_hal_default_font
  end

  def self.theme_night()
    LVGUI::Native.lv_theme_set_current(
      LVGUI::Native.lv_theme_night_init(205, nil)
    )
  end

  def self.theme_mono()
    LVGUI::Native.lv_theme_set_current(
      LVGUI::Native.lv_theme_mono_init(0, nil)
    )
  end

  def self.theme_nixos(font = nil, button_font = nil)
    LVGUI::Native.lv_theme_set_current(
      LVGUI::Native.lv_theme_nixos_init(font, button_font)
    )
  end

  def self.get_asset_path(asset_path)
    File.join(@@assets_path, asset_path)
  end

  def self.set_assets_path(path)
    @@assets_path = path
  end

  def self.get_font(file, size)
    id = [file, size].join("@")

    return (
      if FONTS[id]
        FONTS[id]
      else
        FONTS[id] = LVGUI::Native.lvgui_get_font(get_asset_path(file), size)
      end
    )
  end

  module LVTask
    def self.create_task(period, prio, task_proc)
      if LVGUI::Native::References[:lvgui_handle_lv_task_callback].nil?
        raise "FATAL: bug in native impl of lvgui_handle_lv_task_callback (it is nil)..."
      end

      LVGUI::Native.lv_task_create(
        LVGUI::Native::References[:lvgui_handle_lv_task_callback],
        period,
        prio,
        task_proc
      )
    end

    def self.handle_tasks()
      #$stderr.puts "-> handle_tasks"
      LVGUI::Native.lv_task_handler()
      #$stderr.puts "<- handle_tasks"
    end

    def self.once(prc, prio: LVGL::TASK_PRIO::MID)
      t = self.create_task(0, prio, prc)
      LVGUI::Native.lv_task_once(t)
    end

    def self.delete_task(t)
      LVGUI::Native.lv_task_del(t)
    end
  end
end
