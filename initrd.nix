{
  device_config,
  stage-1 ? {},

  stdenv,
  makeInitrd,
  runCommand,
  writeScript,

  runCommandCC,
  busybox,
  glibc,

  dropbear,
  fbv,
  lib,
  mkExtraUtils,
}:

let
  inherit (lib) optionalString optionals optional;

  device_name = device_config.name;
  device_info = device_config.info;

  extraUtils = mkExtraUtils {
    name = device_name;
    packages = [
      busybox
      fbv
      { package = dropbear; extraCommand = "cp -pv ${glibc.out}/lib/libnss_files.so.* $out/lib"; }
    ]
      ++ optionals (stage-1 ? extraUtils) stage-1.extraUtils
    ;
  };

  shell = "${extraUtils}/bin/ash";

  stage1 = writeScript "stage1" ''
    #!${shell}
    export PATH=${extraUtils}/bin/
    export LD_LIBRARY_PATH=${extraUtils}/lib

    mkdir -p /bin
    ln -sv ${shell} /bin/sh

    mkdir -p /proc /sys /dev /etc/udev /tmp /run/ /lib/ /mnt/ /var/log /etc
    mount -t devtmpfs devtmpfs /dev/
    mount -t proc proc /proc
    mount -t sysfs sysfs /sys

    # /dev/pts (needed for ssh or telnet)
    mkdir -p /dev/pts
    mount -t devpts devpts /dev/pts

    show_splash() {
      echo | fbv -cafei /$1.png > /dev/null 2>&1
    }

    set_framebuffer_mode() {
      # Uses the first defined mode
      if [ -e /etc/fb.modes ]; then
        fbset $(grep ^mode /etc/fb.modes | head -n1 | cut -d'"' -f2)
      else
        [ -e "/sys/class/graphics/fb0/modes" ] || return
        [ -z "$(cat /sys/class/graphics/fb0/mode)" ] || return
        
        _mode="$(cat /sys/class/graphics/fb0/modes)"
        echo "Setting framebuffer mode to: $_mode"
        echo "$_mode" > /sys/class/graphics/fb0/mode
      fi

      ${
        # Start tools like msm-fb-refresher
        lib.optionalString (stage-1 ? initFramebuffer) stage-1.initFramebuffer
      }
    }

    set_framebuffer_mode

    show_splash loading

    loop_forever() {
        while true; do
            sleep 3600
        done
    }


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
    ]
      ++ optional (stage-1 ? fb_modes) { object = stage-1.fb_modes; symlink = "/etc/fb.modes"; }
    ;
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
