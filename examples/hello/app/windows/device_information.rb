module GUI
  class DeviceInformationWindow < LVGUI::BaseWindow
    include LVGUI::ButtonPalette
    include LVGUI::Window::WithBackButton
    goes_back_to ->() { MainWindow.instance }

    def distro_info()
      info = File.read("/etc/lsb-release").split("\n").map do |line|
        k, v = line.split("=", 2)
        v = v.sub(/^"/, "").sub(/"$/, "")
        [k, v]
      end.to_h

      "OS release: #{info["DISTRIB_DESCRIPTION"]}"
    end

    def kernel_info()
        "Kernel release: #{`uname -r`.strip}"
    end

    def device_info()
      if File.exist?("/sys/class/dmi/id/product_name")
        return "Product Name: #{File.read("/sys/class/dmi/id/product_name").strip}"
      end
      if File.exist?("/proc/device-tree/model")
        return "DT Model: #{File.read("/proc/device-tree/model").delete("\u0000").strip}"
      end

      nil
    end

    # Tries to guess at a user-facing CPU name.
    def cpu_name()
      name =
        if File.exist?("/sys/devices/soc0") then
          [
            File.read("/sys/devices/soc0/family").strip,
            File.read("/sys/devices/soc0/machine").strip,
          ].compact.join(" ")
        else
          info = JSON.parse(`lscpu --json`)["lscpu"].map{|data| [data["field"], data["data"]]}.to_h
          # We're stripping some of the model name to improve readability
          info["Model name:"]
            .gsub(/\(R\)/, " ")
            .gsub(/\(TM\)/, " ")
            .gsub(/\bCPU\b/, " ")
            .sub(/@\s*\d+\.\d+GHz/, "").strip
            .sub(/ 0$/, "")
            .gsub(/\s+/, " ").strip
        end
      "Processor: #{name}"
    end

    # bios_date:02/06/2015
    # bios_release:0.0
    # bios_vendor:EFI Development Kit II / OVMF
    # bios_version:0.0.0
    # chassis_type:1
    # chassis_vendor:QEMU
    # chassis_version:pc-i440fx-7.0
    # product_name:Standard PC (i440FX + PIIX, 1996)
    # product_version:pc-i440fx-7.0
    # sys_vendor:QEMU
    def dmi_info()
      dmi_path = "/sys/class/dmi/id"
      return nil unless File.exist?(dmi_path)
      info = [
        "bios_date",
        "bios_release",
        "bios_vendor",
        "bios_version",
        "chassis_type",
        "chassis_vendor",
        "chassis_version",
        "product_name",
        "product_version",
        "sys_vendor",
      ].map do |key|
        path = File.join(dmi_path, key)
        if File.exist?(path) then
          "  - #{key}: #{File.read(path).strip}"
        else
          nil
        end
      end.compact.join("\n")

      [
        "DMI information:",
        info,
      ].join("\n")
    end

    #  {"Architecture:"=>"x86_64",
    #   "Address sizes:"=>"46 bits physical, 48 bits virtual",
    #   "BogoMIPS:"=>"6583.82",
    #   "Byte Order:"=>"Little Endian",
    #   "CPU family:"=>"6",
    #   "CPU max MHz:"=>"3900.0000",
    #   "CPU min MHz:"=>"1200.0000",
    #   "CPU op-mode(s):"=>"32-bit, 64-bit",
    #   "CPU(s):"=>"12",
    #   "Core(s) per socket:"=>"6",
    #   "Flags:"=>"fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc cpuid aperfmperf pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 cx16 xtpr pdcm pcid dca sse4_1 sse4_2 x2apic popcnt tsc_deadline_timer aes xsave avx lahf_lm epb ssbd ibrs ibpb stibp tpr_shadow vnmi flexpriority ept vpid xsaveopt dtherm ida arat pln pts md_clear flush_l1d",
    #   "L1d cache:"=>"192 KiB (6 instances)",
    #   "L1i cache:"=>"192 KiB (6 instances)",
    #   "L2 cache:"=>"1.5 MiB (6 instances)",
    #   "L3 cache:"=>"15 MiB (1 instance)",
    #   "Model name:"=>"Intel(R) Xeon(R) CPU E5-1660 0 @ 3.30GHz",
    #   "Model:"=>"45",
    #   "NUMA node(s):"=>"1",
    #   "NUMA node0 CPU(s):"=>"0-11",
    #   "On-line CPU(s) list:"=>"0-11",
    #   "Socket(s):"=>"1",
    #   "Stepping:"=>"7",
    #   "Thread(s) per core:"=>"2",
    #   "Vendor ID:"=>"GenuineIntel",
    #   "Virtualization:"=>"VT-x",
    #   "Vulnerability Itlb multihit:"=>"KVM: Vulnerable",
    #   "Vulnerability L1tf:"=>"Mitigation; PTE Inversion; VMX vulnerable",
    #   "Vulnerability Mds:"=>"Vulnerable; SMT vulnerable",
    #   "Vulnerability Meltdown:"=>"Vulnerable",
    #   "Vulnerability Spec store bypass:"=>"Vulnerable",
    #   "Vulnerability Spectre v1:"=>"Vulnerable: __user pointer sanitization and usercopy barriers only; no swapgs barriers",
    #   "Vulnerability Spectre v2:"=>"Vulnerable, IBPB: disabled, STIBP: disabled",
    #   "Vulnerability Srbds:"=>"Not affected",
    #   "Vulnerability Tsx async abort:"=>"Not affected"}

    # "Architecture:" => "aarch64"
    # "BogoMIPS:" => "48.00"
    # "Byte Order:" => "Little Endian"
    # "CPU max MHz:" => "1800.0000"
    # "CPU min MHz:" => "408.0000"
    # "CPU op-mode(s):" => "32-bit, 64-bit"
    # "CPU(s):" => "6"
    # "Core(s) per socket:" => "3"
    # "Flags:" => "fp asimd evtstrm aes pmull sha1 sha2 crc32 cpuid"}
    # "Model name:" => "Cortex-A53"
    # "Model:" => "4"
    # "NUMA node(s):" => "1"
    # "NUMA node0 CPU(s):" => "0-5"
    # "On-line CPU(s) list:" => "0-5"
    # "Socket(s):" => "2"
    # "Stepping:" => "r0p4"
    # "Thread(s) per core:" => "1"
    # "Vendor ID:" => "ARM"
    # "Vulnerability Itlb multihit:" => "Not affected"
    # "Vulnerability L1tf:" => "Not affected"
    # "Vulnerability Mds:" => "Not affected"
    # "Vulnerability Meltdown:" => "Not affected"
    # "Vulnerability Spec store bypass:" => "Not affected"
    # "Vulnerability Spectre v1:" => "Mitigation; __user pointer sanitization"
    # "Vulnerability Spectre v2:" => "Mitigation; Branch predictor hardening"
    # "Vulnerability Srbds:" => "Not affected"
    # "Vulnerability Tsx async abort:" => "Not affected"
    def cpu_info()
      info = JSON.parse(`lscpu --json`)["lscpu"].map{|data| [data["field"], data["data"]]}.to_h
      fields = [
        "Architecture:",
        "Vendor ID:",
        "Model name:",
        "CPU(s):",
        "CPU min MHz:",
        "CPU max MHz:",
      ].map do |key|
        if info[key] then
          " - #{key} #{info[key]}"
        else
          nil
        end
      end.compact.join("\n")

      # grep . /sys/devices/soc0/*
      # /sys/devices/soc0/family:Snapdragon
      # /sys/devices/soc0/machine:SDM845
      # /sys/devices/soc0/revision:2.1
      # /sys/devices/soc0/serial_number:000000000
      # /sys/devices/soc0/soc_id:321
      if File.exist?("/sys/devices/soc0") then
        fields << [
          " - soc0 Family: #{File.read("/sys/devices/soc0/family").strip}",
          " - soc0 Machine: #{File.read("/sys/devices/soc0/machine").strip}",
        ].join("\n")
      end

      return nil if fields == ""
      [
        "CPU info:",
        fields,
      ].join("\n")
    end

    def mem_info()
      info = File.read("/proc/meminfo").split(/\n/).map do |line|
        line.split(":", 2).map(&:strip)
      end.to_h

      # This will never show the "correct" advertised memory amount, but is
      # what `free -m` would show under Total.
      total = info["MemTotal"].split(" ").first.to_f / 1024
      "Memory: ~#{total.round} MiB"
    end

    def initialize()
      super()

      LVGL::LVLabel.new(@container).tap do |label|
        text = [
          distro_info,
          kernel_info,
          "",
          device_info,
          cpu_name,
          mem_info,
          "",
          cpu_info,
          "",
          dmi_info,
        ]

        label.set_long_mode(LVGL::LABEL_LONG::BREAK)
        label.set_text(text.compact.join("\n"))
        label.set_align(LVGL::LABEL_ALIGN::LEFT)
        label.set_width(@container.get_width_fit)
      end
    end
  end
end
