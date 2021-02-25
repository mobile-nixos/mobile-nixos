# Loosely inspired by:
# https://github.com/ruby/ruby/blob/ruby_2_7/lib/tmpdir.rb
module Tmp
  extend self

  UNUSABLE_CHARS = [File::SEPARATOR, File::ALT_SEPARATOR, File::PATH_SEPARATOR, ":"].uniq.join("").freeze

  def dir()
    tmp = nil
    [ENV["TMPDIR"], ENV["TMP"], ENV["TEMP"], "/tmp", "."].each do |dir|
      next if !dir
      dir = File.expand_path(dir)
      if stat = File.stat(dir) and stat.directory? and stat.writable?
        tmp = dir
        break
      end rescue nil
    end
    raise ArgumentError, "could not find a temporary directory" unless tmp
    tmp
  end

  def _name(basename)
    n = nil
    prefix, suffix = basename
    prefix = (String.try_convert(prefix) or
              raise ArgumentError, "unexpected prefix: #{prefix.inspect}")
    prefix = prefix.delete(UNUSABLE_CHARS)
    suffix &&= (String.try_convert(suffix) or
                raise ArgumentError, "unexpected suffix: #{suffix.inspect}")
    suffix &&= suffix.delete(UNUSABLE_CHARS)
    begin
      t = Time.now.strftime("%Y%m%d")
      path = "#{prefix}#{t}-#{$$}-#{rand(0x100000000).to_s(36)}"\
        "#{n ? %[-#{n}] : ''}#{suffix||''}"
      path = File.join(dir(), path)
    rescue Errno::EEXIST
      n ||= 0
      n += 1
      retry if !max_try or n < max_try
      raise "cannot generate temporary name using `#{basename}' under `#{tmpdir}'"
    end
    path
  end

  def mkdir(basename = "tmpdir")
    path = _name(basename)
    Dir.mkdir(path, 0700)
    if block_given?
      begin
        yield path.dup
      ensure
        FileUtils.remove_entry path
      end
    else
      path
    end
  end
end
