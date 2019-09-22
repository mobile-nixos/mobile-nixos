hashes = {
  "ESP.img"   => "d70b24594f0615b83fddb8608b4819432380359bc5c6763d7c318e0c3233ea64",
  "FAT32.img" => "73ab1acd845fd0f7f5ddd30edea074f0b14bf4f2b4137f904a90939f1cb2ac8d",
  "Ext4.img"  => "56181a43406c4ba731ed14b3ed32ed6c169b1c2abfe385eef989faef55e3cd07",
}

filetypes = {
  "ESP.img"   => 'DOS/MBR boot sector, code offset 0x3c+2, OEM-ID "mkfs.fat", reserved sectors 32, root entries 512, sectors 1000 (volumes <=32 MB), Media descriptor 0xf8, sectors/FAT 3, sectors/track 32, heads 64, serial number 0x89abcdef, label: "ESP        ", FAT (12 bit)',
  "FAT32.img" => 'DOS/MBR boot sector, code offset 0x3c+2, OEM-ID "mkfs.fat", reserved sectors 32, root entries 512, sectors 1000 (volumes <=32 MB), Media descriptor 0xf8, sectors/FAT 3, sectors/track 32, heads 64, serial number 0x89abcdef, label: "FAT32      ", FAT (12 bit)',
  "Ext4.img"  => 'Linux rev 1.0 ext4 filesystem data, UUID=44444444-4444-4444-1324-123456789098, volume name "Ext4" (extents) (large files)'
}

# By globbing on the output, we can validate all built images are verified.
# The builder should have built everything under `fileSystems`.
Dir.glob(File.join($result, "**/*")) do |file|
  name = File.basename(file)
  sha256sum(name, hashes[name])
  file(name, filetypes[name])
end
