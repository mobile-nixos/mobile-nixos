#!/bin/sh

# By default, it will use `/sys/firmware/fdt` as a source to forward from.
# The source can be overriden using the FDT variable, or `--fdt`.
#
# Example usage:
#
# fdt-forward \
#	--print-header \
#	--copy-dtb "./desired-dtb.dtb" \
#	--forward-node "/memory" \
#	--forward-prop "/" "serial-number" \
#	--forward-prop "/soc/mmc@1c10000/wifi@1" "local-mac-address" \
#	  | fdt-forward --to-dtb > out.dtb

set -e
set -u

PATH="@PATH@:$PATH"


# shellcheck disable=2120
to_dts() {
	dtc --sort -I dtb -O dts "$@"
}

# shellcheck disable=2120
to_dtb() {
	dtc --sort -I dts -O dtb "$@"
}

# Functions with `__` prefixed names are expected to
# be called from `run`, replacing `-` with `_`.

# `--to-dts` will not continue execution further.
# It is a convenience function for calling `dtc`.
__to_dts() {
	to_dts "$@"
}

# `--to-dtb` will not continue execution further.
# It is a convenience function for calling `dtc`.
__to_dtb() {
	to_dtb "$@"
}

# Print a device tree header.
__print_header() {
	printf '/dts-v1/;\n'
	run "$@"
}

# Forwards the *whole* node
__forward_node() {
	node="$1"; shift

	printf '\n// forwarded node: "%s"\n' "$node"
	fdtgrep --show-subnodes --include-node "$node" "$FDT"
	run "$@"
}

# Forwards the prop matching the name from the given node.
__forward_prop() {
	node="$1"; shift
	prop="$1"; shift

	printf '\n// forwarded prop: "%s" from node: "%s"\n' "$prop" "$node"
	# In order, we get the node (without descendents!) as dts
	# Synthesize it back into dtb
	# Then we can get the desired prop.
	fdtgrep --show-version --include-node "$node" "$FDT" \
		| to_dtb \
		| fdtgrep "$prop" -

	# Doing otherwise would give us *all* matching prop names,
	# and not exclusively the one for the desired node.
	run "$@"
}

# Copy the whole dtb as dts source.
# Its header will be stripped.
__copy_dtb() {
	dtb="$1"; shift
	printf '\n// Initial dtb copy...\n'
	to_dts "$dtb" | tail -n+2
	run "$@"
}

__fdt() {
	FDT="$1"; shift
	run "$@"
}


FDT="${FDT:-/sys/firmware/fdt}"

run() {
	if [ $# -gt 0 ]; then
		cmd="${1//-/_}"; shift
		"$cmd" "$@"
	fi
}

run "$@"
