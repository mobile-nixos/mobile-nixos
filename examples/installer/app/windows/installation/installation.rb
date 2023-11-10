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
        InstallationSuccessWindow.instance.present
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
      launch_installation()
      super()
    end

    def launch_installation()
      # Don't re-launch installatoin
      return if @installation_launched
      @installation_launched = true

      update_terminal()
      # Register a task to update regularly.
      @task = LVGL::Hacks::LVTask.create_task(200, LVGL::TASK_PRIO::MID, ->() do
        update_terminal()
      end)

      FileUtils.mkdir_p(INSTALLER_PREFIX)
      Configuration.save_json!(INSTALLER_JSON)
      Configuration.save_configuration!(CONFIGURATION_PREFIX)
      MOUNT_POINT =
        if LVGL::Introspection.simulator?
          path = File.join(Dir.pwd, "installer-bogus-root")
          FileUtils.mkdir_p(path)
          path
        else
          "/mnt"
        end

      installation_sequence = [
        ["set", "-e"],

        ["echo", "\n=> Partitioning and formatting..."],
        ["disk-formatter", Configuration::Device.target_disk, INSTALLER_JSON],

        ["echo", "\n=> Installing..."],
        ["automated-installer", MOUNT_POINT, Configuration::Device.boot_partition],

        ["echo", "\n=> Completed!"],
      ]

      installation_sequence = installation_sequence.map(&:shelljoin).join("\n")

      @installer_terminal.command = ["sh", "-c", installation_sequence].shelljoin()
      @installer_terminal.logging_identifier = "installer"
      @installer_terminal.run()
    end

    def on_success()
      @continue_button.set_hidden(false)
    end

    def on_failure()
      @failure_text.set_hidden(false)
      @failure_button.set_hidden(false)

      @failure_text.set_text([
        "Something went wrong when installing.",
        "The system is in an unknown state.",
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
