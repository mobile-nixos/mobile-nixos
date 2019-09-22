hashes = {
  "ESP.img"   => "f9b39d98bfb797b050467ca5214671b5b427b7896cae44d27d2fc8dbceaccd88",
  "FAT32.img" => "79028d8af97ae4400ea2ab36d34e2a80684c9f8d31ea75e3f54d908c75adc3a4",
  "Ext4.img"  => "8182df3038f43cdf2aba6f3980d9fa794affab0f040f9c07450ebbf0d3d8c2ad",
}

filetypes = {
  "ESP.img"   => 'DOS/MBR boot sector, code offset 0x3c+2, OEM-ID "mkfs.fat", reserved sectors 32, root entries 512, sectors 20480 (volumes <=32 MB), Media descriptor 0xf8, sectors/FAT 80, sectors/track 32, heads 64, serial number 0x89abcdef, label: "ESP        ", FAT (16 bit)',
  "FAT32.img" => 'DOS/MBR boot sector, code offset 0x3c+2, OEM-ID "mkfs.fat", reserved sectors 32, root entries 512, sectors 20480 (volumes <=32 MB), Media descriptor 0xf8, sectors/FAT 80, sectors/track 32, heads 64, serial number 0x89abcdef, label: "FAT32      ", FAT (16 bit)',
  "Ext4.img"  => 'Linux rev 1.0 ext4 filesystem data, UUID=44444444-4444-4444-1324-123456789098, volume name "Ext4" (extents) (large files)'
}

# By globbing on the output, we can validate all built images are verified.
# The builder should have built everything under `fileSystems`.
Dir.glob(File.join($result, "**/*")) do |file|
  name = File.basename(file)
  sha256sum(name, hashes[name])
  file(name, filetypes[name])
end
