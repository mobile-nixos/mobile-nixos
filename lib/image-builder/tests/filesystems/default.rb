hashes = {
  "ESP.img"   => "bd5f7e3b8e35e002e9fc4b22de619f3c0ddc2e5d80c8dd4d66728896493a51d3",
  "FAT32.img" => "2298707f7288d7b39fade76589e00ec4eb0fe013e847c35547fbd6da1d989b11",
}

filetypes = {
  "ESP.img"   => 'DOS/MBR boot sector, code offset 0x3c+2, OEM-ID "mkfs.fat", sectors/cluster 4, reserved sectors 4, root entries 512, sectors 20480 (volumes <=32 MB), Media descriptor 0xf8, sectors/FAT 20, sectors/track 32, heads 64, serial number 0x89abcdef, label: "ESP        ", FAT (16 bit)',
  "FAT32.img" => 'DOS/MBR boot sector, code offset 0x3c+2, OEM-ID "mkfs.fat", sectors/cluster 4, reserved sectors 4, root entries 512, sectors 20480 (volumes <=32 MB), Media descriptor 0xf8, sectors/FAT 20, sectors/track 32, heads 64, serial number 0x89abcdef, label: "FAT32      ", FAT (16 bit)',
}

# By globbing on the output, we can validate all built images are verified.
# The builder should have built everything under `fileSystems`.
Dir.glob(File.join($result, "**/*")) do |file|
  name = File.basename(file)
  sha256sum(name, hashes[name])
  file(name, filetypes[name])
end
