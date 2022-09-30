module GUI
  class InstallationInstallationWindow < BaseWindow
    include LVGUI::BaseUIElements
    include LVGUI::ButtonPalette

    INSTALLER_PREFIX = File.join(ENV["XDG_RUNTIME_DIR"], "mobile-installer")
    CONFIGURATION_PREFIX = File.join(ENV["XDG_RUNTIME_DIR"], "mobile-installer", "nixos")
    INSTALLER_JSON = File.join(INSTALLER_PREFIX, "installer.json")

    def initialize()
      super()

      @installer_terminal = GUI::TerminalPuppet.new(@container)
      @installer_terminal.terminal_height = 25

      @continue_button = add_button("Continue", style: :primary) do
        puts("TODO: go to a window explaining to the user that the installation was successful, and they should probably remove the installer media and then reboot button.")
      end
      @continue_button.set_hidden(true)

      @failure_text = add_text("...")
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

      FileUtils.mkdir_p(INSTALLER_PREFIX)
      Configuration.save_json!(INSTALLER_JSON)
      Configuration.save_configuration!(CONFIGURATION_PREFIX)

      # FIXME: call the actual installer...
      temp_script = [
        #["set", "-x"],
        ["echo", ":: Fake installing"],
        ["sleep", "2"],
        ["echo", ":: Configuration:"],
        ["awk", '{print $0; system("sleep .02");}', File.join(CONFIGURATION_PREFIX, "configuration.nix")],
        ["echo", "Finalizing..."],
        ["sleep", "2"],

        #["echo", "Finished!"],

        ["echo", "FAILURE!"],
        ["exit", "42"],
      ].map(&:shelljoin).join("\n")

      @installer_terminal.command = ["sh", "-c", temp_script].shelljoin()
      @installer_terminal.run()

      super()
    end

    def on_success()
      @continue_button.set_hidden(false)
    end

    def on_failure()
      @failure_text.set_hidden(false)
      @failure_button.set_hidden(false)

      @failure_text.set_text([
        "Something went wrong when installing.",
        "The system is in an uknown state.",
        "\nReturn value: #{@installer_terminal.pane_dead_status}",
      ].join("\n"))
    end

    def update_terminal()
      begin
        if @installer_terminal.pane_dead?
          cleanup()
          if @installer_terminal.pane_dead_status == 0 then
            on_success()
          else
            on_failure()
          end
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
