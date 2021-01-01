# This module augments Fiddle with useful helpers.

module LVGL
end
module LVGL::Fiddlier
  # Given a +type+, returns the value of the global +name+.
  def get_global!(type, name)
    addr = handler.sym(name)
    raise(Fiddle::DLError, "cannot find symbol #{name}") unless addr
    s = struct(["#{type} value"])
    s.new(addr).value
  end

  # Given a +type+, sets the global +name+ to +new_value+.
  def set_global!(type, name, new_value)
    addr = handler.sym(name)
    raise(Fiddle::DLError, "cannot find symbol #{name}") unless addr
    s = struct(["#{type} value"])
    tmp = s.new(addr)
    tmp.value = new_value
    tmp.value
  end

  def get_global_struct!(struct, name)
    addr = handler.sym(name)
    raise(Fiddle::DLError, "cannot find symbol for struct #{name}") unless addr
    struct.new(addr)
  end

  # Using +set_global!+ and +get_global!+, creates accessors for a global
  # variable.
  def global!(type, name)
    method_name = name.to_sym
    define_method(method_name) do
      get_global!(type, name)
    end
    module_function method_name

    method_name = "#{name}=".to_sym
    define_method(method_name) do |value|
      set_global!(type, name, value)
    end
    module_function method_name
  end

  # TODO: parse `typedef enum {...} name;`
  def enum!(name, values, type: "int")
    typedef name.to_s, type.to_s
    mod = self.const_set(name.to_sym, Module.new)
    current_value = 0
    values.each do |data|
      if data.is_a? Hash
        name = data.keys.first.to_sym
        current_value = data.values.first
      else
        name = data.to_sym
      end
      mod.const_set(name, current_value)

      current_value += 1
    end
  end

  # Flattens the given nested struct
  def flatten_struct!(fields, prefix: nil)
    fields.map do |field|
      type = field.first
      name = [prefix, field.last].compact.join("_")

      if type.is_a? Array then
        flatten_struct!(type, prefix: name)
      else
        [[type.to_sym, name.to_sym]]
      end
    end.flatten(1)
  end

  # Parses nested structs into a flattened Fiddle struct.
  # XXX: broken because of struct alignment padding / packing
  #      -> http://www.catb.org/esr/structure-packing/#_padding
  def struct!(fields)
    flattened = flatten_struct!(fields).map do |field|
      type = field.first
      name = field.last
      "#{type} #{name}"
    end
    struct(flattened)
  end

  # Define the given +sym+ as a function.
  # It will auto-wrap the method using a closure.
  def bound_method!(sym, sig)
    sym = sym.to_sym
    module_function sym
    ctx = self
    @func_map[sym.to_s] = bind(sig) do |*args|
      ctx.send(sym, *args)
    end
  end
end
