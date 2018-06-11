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

  strace,
  msm-fb-refresher,
  dropbear,
  fbv,
  lib,

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
    # Copy fbv
    for BIN in ${fbv}/{s,}bin/*; do
      copy_bin_and_libs $BIN
    done
    # Copy dropbear
    for BIN in ${dropbear}/{s,}bin/*; do
      copy_bin_and_libs $BIN
    done
    # Needed for dropbear
    cp -pv ${glibc.out}/lib/libnss_files.so.* $out/lib
    # Copy strace
    for BIN in ${strace}/{s,}bin/*; do
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
    export LD_LIBRARY_PATH=${extraUtils}/lib

    mkdir -p /proc /sys /dev /etc/udev /tmp /run/ /lib/ /mnt/ /var/log /etc/plymouth /bin
    mount -t devtmpfs devtmpfs /dev/
    mount -t proc proc /proc
    mount -t sysfs sysfs /sys

    # Some things will like having /etc/.
    mkdir -p /etc

    show_splash() {
      echo | fbv -afeci /$1.png > /dev/null 2>&1
    }

    set_framebuffer_mode() {
        [ -e "/sys/class/graphics/fb0/modes" ] || return
        [ -z "$(cat /sys/class/graphics/fb0/mode)" ] || return

        _mode="$(cat /sys/class/graphics/fb0/modes)"
        echo "Setting framebuffer mode to: $_mode"
        echo "$_mode" > /sys/class/graphics/fb0/mode
    }

    echo 1 > /sys/class/leds/lcd-backlight/brightness

    set_framebuffer_mode

    msm-fb-refresher --loop &

    show_splash loading

    ln -sv ${shell} /bin/sh

    loop_forever() {
        while true; do
            sleep 3600
        done
    }

    # /dev/pts (needed for telnet)
    mkdir -p /dev/pts
    mount -t devpts devpts /dev/pts


    IP=172.16.42.1
    TELNET_PORT=23

    setup_usb_network_android() {
            # Only run, when we have the android usb driver
            SYS=/sys/class/android_usb/android0
            [ -e "$SYS" ] || return
            # Do the setup
            printf "%s" "0" >"$SYS/enable"
            printf "%s" "18D1" >"$SYS/idVendor"
            printf "%s" "D001" >"$SYS/idProduct"
            printf "%s" "rndis" >"$SYS/functions"
            printf "%s" "1" >"$SYS/enable"
    }
    setup_usb_network_configfs() {
            CONFIGFS=/config/usb_gadget
            [ -e "$CONFIGFS" ] || return
            mkdir $CONFIGFS/g1
            printf "%s" "18D1" >"$CONFIGFS/g1/idVendor"
            printf "%s" "D001" >"$CONFIGFS/g1/idProduct"
            mkdir $CONFIGFS/g1/strings/0x409
            mkdir $CONFIGFS/g1/functions/rndis.usb0
            mkdir $CONFIGFS/g1/configs/c.1
            mkdir $CONFIGFS/g1/configs/c.1/strings/0x409
            printf "%s" "rndis" > $CONFIGFS/g1/configs/c.1/strings/0x409/configuration
            ln -s $CONFIGFS/g1/functions/rndis.usb0 $CONFIGFS/g1/configs/c.1
            # See also: #338
            # shellcheck disable=SC2005
            echo "$(ls /sys/class/udc)" > $CONFIGFS/g1/UDC
    }
    setup_usb_network() {
            # Only run once
            _marker="/tmp/_setup_usb_network"
            [ -e "$_marker" ] && return
            touch "$_marker"
            echo "Setup usb network"
            # Run all usb network setup functions (add more below!)
            setup_usb_network_android
            setup_usb_network_configfs
    }
    start_udhcpd() {
            # Only run once
            [ -e /etc/udhcpd.conf ] && return

            # Get usb interface
            INTERFACE=""
            ifconfig rndis0 "$IP" && INTERFACE=rndis0
            if [ -z $INTERFACE ]; then
                    ifconfig usb0 "$IP" && INTERFACE=usb0
            fi
            if [ -z $INTERFACE ]; then
                    ifconfig eth0 "$IP" && INTERFACE=eth0
            fi
            # Create /etc/udhcpd.conf
            {
                    echo "start 172.16.42.2"
                    echo "end 172.16.42.2"
                    echo "auto_time 0"
                    echo "decline_time 0"
                    echo "conflict_time 0"
                    echo "lease_file /var/udhcpd.leases"
                    echo "interface $INTERFACE"
                    echo "option subnet 255.255.255.0"
            } >/etc/udhcpd.conf
            echo "Start the dhcpcd daemon (forks into background)"
            udhcpd
    }

    # Hack~ish
    echo -e '#!/bin/sh\necho b > /proc/sysrq-trigger' > /bin/reboot
    chmod +x /bin/reboot

    setup_usb_network
    start_udhcpd

    #sleep 5

    #
    # Oh boy, that's insecure!
    #
    echo '${shell}' > /etc/shells
    echo 'root:x:0:0:root:/root:${shell}' > /etc/passwd
    echo 'passwd: files' > /etc/nsswitch.conf
    passwd -u root
    passwd -d root
    mkdir -p /root/.ssh
    mkdir -p /etc/dropbear/
    echo "From a mobile-nixos device ${device_name}" >> /etc/banner

    mkdir -p /var/log
    touch /var/log/lastlog

    # This is the "everything is going wrong" way to debug.
    # # ---- START nc
    # # THIS IS HIGHLY INSECURE
    # nc -lk -p 2323 -e ${shell} &
    # # ---- END nc

    # telnetd -p ''${TELNET_PORT} -l ${shell} &

    # THIS IS HIGHLY INSECURE
    # This allows blank login passwords.
    dropbear -ERB -b /etc/banner

    show_splash splash

    loop_forever
  '';
  ramdisk = makeInitrd {
    contents = [
      { object = stage1; symlink = "/init"; }
      { object = ./temp-splash.png; symlink = "/splash.png"; }
      { object = ./loading.png; symlink = "/loading.png"; }
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
