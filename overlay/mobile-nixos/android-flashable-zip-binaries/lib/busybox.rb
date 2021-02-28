module Busybox
  extend self

  @@tmpdir = Tmp.mkdir("afzb-busybox")
  @@binary = File.join(@@tmpdir, "busybox")

  @@last_status = nil

  def last_status()
    @@last_status
  end

  def _init()
    # Offset to read the busybox binary offset from.
    offset = File.size($0) - 4

    File.open($0, "rb") do |f|
      f.seek(offset)
      # Read the big-endian (network byte order) offset
      busybox_offset = f.read(4).unpack1("N")
      f.seek(busybox_offset)

      File.delete(@@binary) if File.exist?(@@binary)
      File.open(@@binary, "wb") do |busybox|
        busybox.write(f.read(offset - busybox_offset))
      end
      File.chmod(0555, @@binary)
    end
  end

  _init()

  def _cleanup()
    FileUtils.remove_entry(@@tmpdir)
  end

  def _call(*cmd)
    $stderr.puts " $ #{[@@binary, *cmd].shelljoin}"
    # Doing the following may fail, as /bin/sh is missing and +Kernel#`+ uses
    # +IO.popen+, which uses /bin/sh.
    #`#{[@@binary, *cmd].shelljoin}`

    # +Open3.capture2e+ uses execve through its own +Open3.spawn+
    # An improvement would be to work with IO pipes so executables stream their
    # output to the Edify-based UI.
    out, @@last_status = Open3.capture2e(@@binary, *cmd)
    out
  end

  def method_missing(*args)
    _call(*args.map(&:to_s))
  end
end
