class FlashPlan
  class AssertDevice
    def initialize(device_name)
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
  end

  class FlashPartition
    def initialize(partname, zip: nil)
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
      # FIXME
      Edify.ui_print("Flashing #{@partname.inspect}")
      args = [
        "if=#{file}",
        "of=#{@device}",
        "conv=fsync",
        "bs=#{4*1024*1024}",
      ]
      Edify.ui_print(" $ " + ["dd", *args].shelljoin)
      Edify.ui_print(Busybox.dd(*args))
      Busybox.last_status.success?
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

    def explain()
      "Flash partition #{@partname.inspect} with image #{@zip.inspect}"
    end

    def relative_size()
      file_size
    end
  end

  def initialize()
    @plan = []
  end

  def flash_partition(*args)
    @plan << FlashPartition.new(*args)
  end

  def assert_device(*args)
    @plan << AssertDevice.new(*args)
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
    total = @plan.map(&:relative_size).reduce(&:+).to_f

    # Startings at 0%
    current = 0

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

      # Progress up to now
      current += item.relative_size / total
      Edify.set_progress(current)
    end

    Edify.ui_print("")
    Edify.ui_print(":: Flash plan completed successfully.")
    Edify.ui_print("No errors to report.")
    Edify.ui_print("")
  end
end
