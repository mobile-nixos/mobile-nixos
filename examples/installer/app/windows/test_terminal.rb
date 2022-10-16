module GUI
  class TerminalTestWindow < BaseWindow
    include LVGUI::BaseUIElements
    include LVGUI::ButtonPalette

    def initialize()
      super()

      @terminal_widget = GUI::TerminalPuppet.new(@container)
      @terminal_widget.terminal_height = 25

      add_buttons([
        ["Quit",  ->() {
          cleanup()
          MainWindow.instance.present
        }],
      ])
    end

    def present()
      run_commands()
      super()
    end

    def run_commands()
      return if @commands_running
      @commands_running = true

      update_terminal()
      # Register a task to update regularly.
      @task = LVGL::Hacks::LVTask.create_task(200, LVGL::TASK_PRIO::MID, ->() do
        update_terminal()
      end)

      commands_sequence = [
        ["set", "-e"],

        ["echo", "\n=> Fake command"],
        ["sleep", "1"],
        ["echo", "\n..."],
        ["sleep", "1"],
        ["echo", "\n..."],

        ["echo", "\n=> Doing stuff"],
        ["sleep", "1"],
        ["echo", "\n..."],
        ["sleep", "1"],
        ["echo", "\n..."],
        ["sleep", "1"],
        ["echo", "\n..."],
        ["sleep", "1"],
        ["echo", "\n..."],

        ["echo", "\n=> Completed!"],
      ]

      commands_sequence = commands_sequence.map(&:shelljoin).join("\n")

      @terminal_widget.command = ["sh", "-c", commands_sequence].shelljoin()
      @terminal_widget.logging_identifier = "installer"
      @terminal_widget.run()
    end

    def on_success()
      puts "Success!"
    end

    def on_failure()
      puts "Failure!"
    end

    def update_terminal()
      begin
        if @terminal_widget.pane_dead?
          cleanup()
          if @terminal_widget.pane_dead_status == 0 then
            on_success()
          else
            on_failure()
          end
        else
          @terminal_widget.update_terminal
        end
      rescue => e
        $stderr.puts(e.inspect)
      end
    end

    # MUST be called before exiting or changing window.
    def cleanup()
      if @task
        LVGL::Hacks::LVTask.delete_task(@task)
      end
      @terminal_widget.cleanup()
    end
  end
end
