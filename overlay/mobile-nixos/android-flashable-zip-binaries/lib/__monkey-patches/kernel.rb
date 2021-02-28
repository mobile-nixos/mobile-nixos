module Kernel
  def pp(*args)
    args.each do |arg|
      puts(arg.inspect)
    end
  end
end
