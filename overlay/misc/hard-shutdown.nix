{writeScriptBin}:

#
# Forces a shutdown using sysrq-triggers.
#
# This is useful in the initrd where `shutdown` doesn't seem to work.
#
writeScriptBin "hard-shutdown" ''
#!/bin/sh
echo o > /proc/sysrq-trigger
''
