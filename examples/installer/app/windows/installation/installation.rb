module GUI
  class InstallationInstallationWindow < BaseWindow
    include LVGUI::BaseUIElements
    include LVGUI::ButtonPalette

    INSTALLER_JSON = File.join(ENV["XDG_RUNTIME_DIR"], "installer.json")

    def initialize()
      super()

      @installer_terminal = GUI::TerminalPuppet.new(@container)
      @installer_terminal.terminal_height = 25
      # FIXME: custom installer script
      @installer_terminal.command = ["less", INSTALLER_JSON].shelljoin()

      @continue_button = add_button("Continue", style: :primary) do
        puts("TODO: go to a window explaining to the user that the installation was successful, and they should probably remove the installer media and then reboot button.")
      end
      @continue_button.set_hidden(true)

      @failure_text = add_text("Something went wrong when installing.\n\nThe system is in an uknown state.")
      @failure_text.set_hidden(true)
      @failure_button = add_button("Quit", style: :danger) do
        QuitWindow.instance.present
      end
      @failure_button.set_hidden(true)
    end

    def present()
      update_terminal()
      # Register a task to update regularly.
      @task = LVGL::Hacks::LVTask.create_task(200, LVGL::TASK_PRIO::MID, ->() do
        update_terminal()
      end)

      Configuration.save_json!(INSTALLER_JSON)
      @installer_terminal.run()

      super()
    end

    def on_success()
      @continue_button.set_hidden(false)
    end

    def on_failure()
      @failure_text.set_hidden(false)
      @failure_button.set_hidden(false)
    end

    def update_terminal()
      begin
        if @installer_terminal.pane_dead?
          cleanup()
          on_failure()
        else
          @installer_terminal.update_terminal
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
      @installer_terminal.cleanup()
    end
  end
end
