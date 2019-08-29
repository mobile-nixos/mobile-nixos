hashes = {
  "ESP.img"   => "225b07ed075c8e088f973f1002382b07df1e6ca62e43049e9cb7b20534bee796",
  "FAT32.img" => "e4146b21ed3ea287a5a86e7910d678bf056b40374c4f1533191e21b8ce6d48c9",
}

filetypes = {
  "ESP.img"   => 'DOS/MBR boot sector, code offset 0x58+2, OEM-ID "mkfs.fat", sectors 20480 (volumes <=32 MB), Media descriptor 0xf8, sectors/track 32, heads 64, FAT (32 bit), sectors/FAT 158, serial number 0x89abcdef, label: "ESP        "',
  "FAT32.img" => 'DOS/MBR boot sector, code offset 0x58+2, OEM-ID "mkfs.fat", sectors 20480 (volumes <=32 MB), Media descriptor 0xf8, sectors/track 32, heads 64, FAT (32 bit), sectors/FAT 158, serial number 0x89abcdef, label: "FAT32      "',
}

# By globbing on the output, we can validate all built images are verified.
# The builder should have built everything under `fileSystems`.
Dir.glob(File.join($result, "**/*")) do |file|
  name = File.basename(file)
  sha256sum(name, hashes[name])
  file(name, filetypes[name])
end
