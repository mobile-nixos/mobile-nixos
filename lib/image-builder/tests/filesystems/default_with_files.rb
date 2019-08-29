hashes = {
  "ESP.img"   => "40b3ac80866458f31a647e60300beebd4d88ba3eb040558bf2aa5a28db99d130",
  "FAT32.img" => "30f31e93191c364d19986d0a339b5957258f6d3fee401e70c590b5baed5883ee",
}

filetypes = {
  "ESP.img"   => 'DOS/MBR boot sector, code offset 0x58+2, OEM-ID "mkfs.fat", sectors 1000 (volumes <=32 MB), Media descriptor 0xf8, sectors/track 32, heads 64, FAT (32 bit), sectors/FAT 8, serial number 0x89abcdef, label: "ESP        "',
  "FAT32.img" => 'DOS/MBR boot sector, code offset 0x58+2, OEM-ID "mkfs.fat", sectors 1000 (volumes <=32 MB), Media descriptor 0xf8, sectors/track 32, heads 64, FAT (32 bit), sectors/FAT 8, serial number 0x89abcdef, label: "FAT32      "',
}

# By globbing on the output, we can validate all built images are verified.
# The builder should have built everything under `fileSystems`.
Dir.glob(File.join($result, "**/*")) do |file|
  name = File.basename(file)
  sha256sum(name, hashes[name])
  file(name, filetypes[name])
end
