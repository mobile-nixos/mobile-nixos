module Process
  def self.uid()
    # TODO: see if we can implement the following with our mruby
    # https://ruby-doc.org/core-2.5.1/Process.html#method-c-uid
    `id -u`.strip.to_i
  end
end
