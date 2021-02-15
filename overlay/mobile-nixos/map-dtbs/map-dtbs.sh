#!/usr/bin/env bash

# shellcheck disable=SC2123
PATH="@PATH@:${PATH}"

set -u
set -e

# Ugh... xargs complains when the child processes are killed by the pipe being closed.
# This is why there is the indirection into a variable.
_get_compatible() {
	filename="$1"
	for char_text in $(fdtget -tbx "${filename}" / compatible); do
		# shellcheck disable=SC2059
		printf "\\x${char_text}"
	done | xargs --null -n1 echo
}

get_compatible() {
	data=$(_get_compatible "$1")
	local IFS=$'\n'
	for l in ${data}; do
		echo "$l"
		return 0
	done
}

first=1

printf '{\n'
for f in "${@}"; do
	# First line does not handle \n
	# Every other one after add the previous line's comma, and \n
	if ((!first)); then
		printf ",\n"
	fi
	# Not the first line anymore.
	first=0

	printf '  "%s": "%s"' "$(get_compatible "$f")" "$f"
done
printf '\n}'
