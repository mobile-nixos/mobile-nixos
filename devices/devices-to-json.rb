#!/usr/bin/env nix-shell
#!nix-shell -p ruby -p curl -p libarchive -i ruby --pure

require "json"

Dir.chdir(__dir__)

# This script, out-of-band, updates the json data with the latest upstream data.
# Breakage could be expected. Let's make it our job to keep it compatible with
# the format upstream uses.

#UPSTREAM="https://github.com/postmarketOS/pmbootstrap"
# HACK: I need to upstream my device :/
UPSTREAM = "https://github.com/samueldr/pmbootstrap"
ARCHIVE = "#{UPSTREAM}/archive/master.tar.gz"
WORKDIR = "postmarketOS"

`mkdir -p #{WORKDIR}`
`curl -L #{ARCHIVE} | tar -zx -C #{WORKDIR}`

Dir.chdir("#{WORKDIR}/pmbootstrap-master") do
	$devices = {}
	Dir.glob("aports/device/device-*") do |device_dir|
		pm_name = device_dir.split("/").last.sub(/^device-/, "")
		contents = File.read(File.join(device_dir, "deviceinfo"))
			.split("\n")
			.grep(/^deviceinfo_/)
			.map { |str| str.sub(/^deviceinfo_/, "") }
			.map { |str| str.split("=", 2) }
			.to_h
			.map do |k, v|
			# This *tries* to parse the bash values as json to piggy-back
			# on the string escapes.
			begin
				v = JSON.parse(v)
			rescue JSON::ParserError
			end

			v = true if v == "true"
			v = false if v == "false"

			[k, v]
		end
			.to_h

		contents["pm_name"] = pm_name
		$devices[pm_name] = contents
	end
end

File.open("postmarketOS-devices.json", "w") do |f|
	f.write(JSON.pretty_generate($devices))
end
