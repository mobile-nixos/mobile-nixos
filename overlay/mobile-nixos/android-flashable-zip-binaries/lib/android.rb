module Android
  extend self

  def get_prop(propname, default = nil)
    prop, st = Open3.capture2("getprop", propname)
    prop.strip!
    if prop == ""
      default
    else
      prop
    end
  end
end
