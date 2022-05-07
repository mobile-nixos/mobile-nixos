#module GUI
#  class TempTerminalWindow < BaseWindow
#    include LVGUI::BaseUIElements
#    include LVGUI::ButtonPalette
#    def initialize()
#      p "→ TempTerminalWindow#initialize"
#      super()
#
#      @tmux = GUI::TerminalPuppet.new(@container)
#      @tmux.terminal_height = 20
#      #@tmux.command = "nano"
#      @tmux.command = "man nix-build"
#
#      add_buttons([
#        ["Quit",  ->() {
#          cleanup()
#          QuitWindow.instance.present
#        }],
#      ])
#    end
#
#    def present()
#      p "→ TempTerminalWindow#present"
#      @tmux.run()
#
#      update_terminal()
#      # Register a task to update regularly.
#      @task = LVGL::Hacks::LVTask.create_task(200, LVGL::TASK_PRIO::MID, ->() do
#        p "→ TempTerminalWindow@task"
#        update_terminal()
#      end)
#
#      super()
#    end
#
#    def update_terminal()
#      p "→ TempTerminalWindow#update_terminal"
#      begin
#        if @tmux.puppet.pane_dead?
#          @tmux.cleanup()
#          @tmux.run()
#        end
#        @tmux.update_terminal
#      rescue => e
#        $stderr.puts(e.inspect)
#      end
#    end
#
#    # MUST be called before exiting or changing window.
#    def cleanup()
#      p "→ TempTerminalWindow#cleanup"
#      if @task
#        LVGL::Hacks::LVTask.delete_task(@task)
#      end
#      @tmux.cleanup()
#    end
#  end
#end
