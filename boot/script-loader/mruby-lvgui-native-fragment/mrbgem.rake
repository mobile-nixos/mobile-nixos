MRuby::Gem::Specification.new("mruby-lvgui-native-fragment") do |spec|
  spec.license = "MIT"
  spec.authors = "Samuel Dionne-Riel"
  spec.version = "0.0.1"

  # Ensures `lvgui` is built into the mruby interpreter.
  spec.cc.include_paths << `pkg-config --cflags lvgui`.chomp
  spec.linker.flags_after_libraries << `pkg-config --libs lvgui`.chomp

  # Also declare dependencies properly here.
  spec.add_dependency('mruby-fiddle')

  spec.rbfiles = [
    # Left empty by design, look under boot/lib
  ]
end
