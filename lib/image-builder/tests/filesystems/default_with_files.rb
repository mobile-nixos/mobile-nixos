hashes = {
  "ESP.img"   => "9b53acc0332e4b143e31203dc0df02de929c3bcff9b36799c651f1c8d5eaca4c",
  "FAT32.img" => "9b76804f3624566664132134d28208fce005bfe5d3dad3da9d91814f7ca2286f",
  "Ext4.img"  => "abcf53929fc3271965c7a8c93f45a3bf6144a3b8a371d26fca2e5e0b3eac1f8e",
}

filetypes = {
  "ESP.img"   => 'DOS/MBR boot sector, code offset 0x58+2, OEM-ID "mkfs.fat", sectors 1000 (volumes <=32 MB), Media descriptor 0xf8, sectors/track 32, heads 64, FAT (32 bit), sectors/FAT 8, serial number 0x89abcdef, label: "ESP        "',
  "FAT32.img" => 'DOS/MBR boot sector, code offset 0x58+2, OEM-ID "mkfs.fat", sectors 1000 (volumes <=32 MB), Media descriptor 0xf8, sectors/track 32, heads 64, FAT (32 bit), sectors/FAT 8, serial number 0x89abcdef, label: "FAT32      "',
  "Ext4.img"  => 'Linux rev 1.0 ext4 filesystem data, UUID=44444444-4444-4444-1324-123456789098, volume name "Ext4" (extents) (large files)'
}

# By globbing on the output, we can validate all built images are verified.
# The builder should have built everything under `fileSystems`.
Dir.glob(File.join($result, "**/*")) do |file|
  name = File.basename(file)
  sha256sum(name, hashes[name])
  file(name, filetypes[name])
end
