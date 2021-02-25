# It is assumed that `edify` commands are what are sent through the FD.
# https://source.android.com/devices/tech/ota/nonab/inside_packages
# Pretty much confirmed here: https://github.com/LineageOS/android_device_samsung_msm8916-common/blob/e16fe7b6a8044fc80e1adfe010cb8729e048cb0d/releasetools/functions.sh
# And here: https://github.com/TeamWin/Team-Win-Recovery-Project/blob/58f2132bc3954fc704787d477500a209eedb8e29/updater/install.cpp#L1491-L1544
module Edify
  extend self

  @@outfd = IO.new(ARGV[1].to_i, "w")

  def _send(cmd, *args)
    args.map! do |arg|
      arg.to_s.gsub("\n", "")
    end
    @@outfd.puts([cmd, *args].join(" "))
  end

  def ui_print(str)
    # No need to print to the log, it'll be done for us.
    #$stdout.puts str
    if str.nil? || str == ""
      # Force two spaces for the `ui_print` command
      @@outfd.puts("ui_print  ")
    else
      _send(:ui_print, str)
    end
    # Print a newline, as the recovery log will not contain a \n
    $stdout.print("\n")
  end

  def set_progress(f)
    $stdout.puts "Progress: #{f}"
    _send(:set_progress, f)
  end
end
