{
  device_name,

  stdenv,
  makeInitrd,
  runCommand,
  writeScript,

  nukeReferences,
  runCommandCC,
  busybox,
  glibc,

  msm-fb-refresher,

  ...
}:

# TODO : configurable through receiving device-specific informations.
let
  extraUtils = runCommandCC "extra-utils"
  {
    buildInputs = [ nukeReferences ];
    allowedReferences = [ "out" ];
  } ''
    set +o pipefail
    mkdir -p $out/bin $out/lib
    ln -s $out/bin $out/sbin
    copy_bin_and_libs() {
      [ -f "$out/bin/$(basename $1)" ] && rm "$out/bin/$(basename $1)"
      cp -pd $1 $out/bin
    }
    # Copy Busybox
    for BIN in ${busybox}/{s,}bin/*; do
      copy_bin_and_libs $BIN
    done
    # Copy msm-fb-refresher
    for BIN in ${msm-fb-refresher}/{s,}bin/*; do
      copy_bin_and_libs $BIN
    done
    # Copy ld manually since it isn't detected correctly
    cp -pv ${glibc.out}/lib/ld*.so.? $out/lib
    # Copy all of the needed libraries
    find $out/bin $out/lib -type f | while read BIN; do
      echo "Copying libs for executable $BIN"
      LDD="$(ldd $BIN)" || continue
      LIBS="$(echo "$LDD" | awk '{print $3}' | sed '/^$/d')"
      for LIB in $LIBS; do
        TGT="$out/lib/$(basename $LIB)"
        if [ ! -f "$TGT" ]; then
          SRC="$(readlink -e $LIB)"
          cp -pdv "$SRC" "$TGT"
        fi
      done
    done
    # Strip binaries further than normal.
    chmod -R u+w $out
    stripDirs "lib bin" "-s"
    # Run patchelf to make the programs refer to the copied libraries.
    find $out/bin $out/lib -type f | while read i; do
      if ! test -L $i; then
        nuke-refs -e $out $i
      fi
    done
    find $out/bin -type f | while read i; do
      if ! test -L $i; then
        echo "patching $i..."
        patchelf --set-interpreter $out/lib/ld*.so.? --set-rpath $out/lib $i || true
      fi
    done
    # Make sure that the patchelf'ed binaries still work.
    echo "testing patched programs..."
    $out/bin/ash -c 'echo hello world' | grep "hello world"
    export LD_LIBRARY_PATH=$out/lib
    $out/bin/mount --help 2>&1 | grep -q "BusyBox"
  '';


  shell = "${extraUtils}/bin/ash";

  # TODO : make our own rootfs here!
  # https://github.com/postmarketOS/pmbootstrap/blob/master/aports/main/postmarketos-mkinitfs-hook-maximum-attention/00-maximum-attention.sh
  stage1 = writeScript "stage1" ''
    #!${shell}
    export PATH=${extraUtils}/bin/
    mkdir -p /proc /sys /dev /etc/udev /tmp /run/ /lib/ /mnt/ /var/log /etc/plymouth /bin
    mount -t devtmpfs devtmpfs /dev/
    mount -t proc proc /proc
    mount -t sysfs sysfs /sys
    
    ln -sv ${shell} /bin/sh
    #ln -s ''${modules}/lib/modules /lib/modules
    
    
    
    #echo /sbin/mdev >/proc/sys/kernel/hotplug
    #mdev -s
    
    
    loop_forever() {
    	while true; do
    		sleep 1
    	done
    }
    
    BLINK_INTERVAL=2 # seconds
    VIBRATION_DURATION=500 #ms
    VIBRATION_INTERVAL=1   #s
    
    find_leds() {
    	find /sys -name "max_brightness" | xargs -I{} dirname {}
    }
    
    find_vibrator() {
    	echo /sys/class/timed_output/vibrator
    }
    
    # blink_leds takes a list of LEDs as parameters,
    # it iterates over every LED, and changes their value,
    # alternating between max_brightness and 0 every BLINK_INTERVAL
    blink_leds() {
    	state=false # false = off, true=on
    	while true; do
    		for led in $@; do
    			if [ "$state" = true ]; then
    				cat $led/max_brightness > $led/brightness
    			else
    				echo 0 > $led/brightness
    			fi
    			echo blinking LED: $led
    		done
    		sleep ''${BLINK_INTERVAL}s
    		if [ "$state" = true ]; then
    			state=false
    		else
    			state=true
    		fi
    	done
    }
    
    # vibrate_loop vibrates each VIBRATION_INTERVAL for VIBRATION_DURATION
    # it takes a timed_device path to the vibrator as $1
    vibrate_loop() {
    	if [ ! -f $1/enable ]; then
    		return;
    	fi
    
    	while true; do
    		echo $VIBRATION_DURATION > $1/enable
    		sleep ''${VIBRATION_INTERVAL}s
    	done
    }

    set_framebuffer_mode() {
        [ -e "/sys/class/graphics/fb0/modes" ] || return
        [ -z "$(cat /sys/class/graphics/fb0/mode)" ] || return
    
        _mode="$(cat /sys/class/graphics/fb0/modes)"
        echo "Setting framebuffer mode to: $_mode"
        echo "$_mode" > /sys/class/graphics/fb0/mode
    }

    set_framebuffer_mode

    msm-fb-refresher --loop &

    gzip -c -d /splash.ppm.gz | fbsplash -s -

    # This also blinks the backlight.
    # blink_leds $(find_leds) &
    vibrate_loop $(find_vibrator) &
    
    sleep 15

    # Skip looping forever as this currently does nothing useful.
    # What this means is that the device will reboot after doing
    # whatever has been defined up above.

    # loop_forever
  '';
  ramdisk = makeInitrd {
    contents = [
      { object = stage1; symlink = "/init"; }
      { object = ./temp-splash.ppm.gz; symlink = "/splash.ppm.gz"; }
    ];
  };
in
stdenv.mkDerivation {
  name = "initrd-${device_name}";
  src = builtins.filterSource (path: type: false) ./.;
  unpackPhase = "true";

  installPhase =  ''
    cp ${ramdisk}/initrd $out
  '';
}
