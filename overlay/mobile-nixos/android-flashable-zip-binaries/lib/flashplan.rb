class FlashPlan
  class AssertDevice
    def initialize(plan, device_name)
      @plan = plan
      @device_name = device_name
    end

    def check()
      errors = []
      device = [
        "ro.product.device",
        "ro.build.product",
      ].map do |propname|
        Android.get_prop(propname)
      end.compact.first

      unless device == @device_name
        errors << ["Device does not match. Running on device: #{device.inspect}. Wants device: #{@device_name.inspect}"]
      end

      errors
    end

    def execute()
      # no-op
      true
    end

    def explain()
      # Hidden from the plan
      ""
    end

    def relative_size()
      0
    end

    def handles_progress?()
      false
    end
  end

  class FlashPartition
    def initialize(plan, partname, zip: nil)
      @plan = plan
      @partname = partname
      @zip = zip
      @device = nil
    end

    def check()
      errors = []
      unless File.exist?(file)
        errors << "File #{file.inspect} not found"
      end

      @device, error = Partitions.by_partname(@partname)
      errors << error if error

      unless partition_size >= file_size
        errors << "File #{file.inspect} too big. File is #{file_size} bytes. Partition #{@partname.inspect} is #{partition_size} bytes."
      end

      errors
    end

    def execute()
      Edify.ui_print("Flashing #{@partname.inspect}...")
      current_block = 0

      while current_block*block_size <= file_size do
        args = [
          "if=#{file}",
          "of=#{@device}",
          "count=1",
          "bs=#{block_size}",
          "skip=#{current_block}",
          "seek=#{current_block}",
          "status=none",
        ]

        # Debug logging if needed...
        #Edify.ui_print(" $ " + ["dd", *args].shelljoin)
        $stdout.puts(" $ " + ["dd", *args].shelljoin)

        output = Busybox.dd(*args)
        Edify.ui_print(output) if output.strip != ""
        return false unless Busybox.last_status.success?

        left = file_size - current_block*block_size
        flashed =
          if left > block_size
            block_size
          else
            left
          end
        @plan.increase_progress(flashed)
        current_block += 1
      end

      Edify.ui_print("Syncing #{@partname.inspect}...")
      output = Busybox.sync(@device)
      Edify.ui_print(output) if output.strip != ""

      # Operation was a success
      true
    end

    def file()
      unless File.exist?(@zip)
        Zip.extract(@zip)
      end
      @zip
    end

    def file_size()
      File.size(file)
    end

    def partition_size()
      Busybox.blockdev(
        "--getsize64",
        @device
      ).to_i
    end

    # This mostly affects the granularity of the progress bar updates, at the
    # cost of sometimes a bit slower flashes if done on a low block size.
    def block_size()
      #    KB     MB
      4 * 1024 * 1024
    end

    def explain()
      "Flash partition #{@partname.inspect} with image #{@zip.inspect}"
    end

    def relative_size()
      file_size
    end

    def handles_progress?()
      true
    end
  end

  def initialize()
    @plan = []
  end

  def flash_partition(*args)
    @plan << FlashPartition.new(self, *args)
  end

  def assert_device(*args)
    @plan <<  AssertDevice.new(self, *args)
  end

  def execute!()
    Edify.ui_print("")
    Edify.ui_print(":: Flash plan for this zip")
    @plan.each do |item|
      Edify.ui_print(" - " + item.explain) unless item.explain == ""
    end

    Edify.ui_print("")
    Edify.ui_print(":: Checking flash plan...")
    errors = @plan.map(&:check).flatten
    if errors.count > 0
      Edify.ui_print("Errors detected:")

      errors.each do |err|
        Edify.ui_print(" - #{err}")
      end

      Edify.ui_print("")
      Edify.ui_print("Nothing was done.")

      return
    end
    Edify.ui_print("Plan looks okay... Continuing.")

    # 100% is the relative size of all those tasks.
    @total_progress = @plan.map(&:relative_size).reduce(&:+).to_f

    # Startings at 0%
    @current_progress = 0

    Edify.ui_print("")
    Edify.ui_print(":: Executing flash plan...")
    failed = false
    @plan.each do |item|
      next if failed
      failed = !item.execute

      if failed
        Edify.ui_print("")
        Edify.ui_print("Failure while executing ''#{item.explain}''.")
        Edify.ui_print("")
        next
      end

      increase_progress(item.relative_size) unless item.handles_progress?
    end

    Edify.ui_print("")
    Edify.ui_print(":: Flash plan completed successfully.")
    Edify.ui_print("No errors to report.")
    Edify.ui_print("")
  end

  def increase_progress(added)
    # Progress up to now
    @current_progress += added / @total_progress
    Edify.set_progress(@current_progress)
  end
end
