module Process
  def self.uid()
    # TODO: see if we can implement the following with our mruby
    # https://ruby-doc.org/core-2.5.1/Process.html#method-c-uid
    out, _ = Open3.capture2("id", "-u")
    out.strip.to_i
  end
end
