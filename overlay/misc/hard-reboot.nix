{writeScriptBin}:

#
# Forces a reboot using sysrq-triggers.
#
# This is useful in the initrd where `reboot` doesn't seem to work.
#
writeScriptBin "hard-reboot" ''
#!/bin/sh
echo b > /proc/sysrq-trigger
''
