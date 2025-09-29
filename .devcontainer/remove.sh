#!/bin/sh

HERE="$(dirname "$(realpath "$0")")"

ROOT="$(dirname "$HERE")"

WD="$(pwd)"
if [ "$ROOT" != "$WD" ]; then
	cd "$ROOT" || exit 1
	WD="$ROOT"
fi

PROJECT="$(basename "$ROOT")"

container="${PROJECT}_devcontainer"
volume="${container}_home"

for driver in podman docker; do
	if which "$driver" 1>/dev/null 2>&1; then
		count="$("$driver" ps -a --format "{{.Names}}" | grep -c "$container")"
		if [ "$count" -gt 0 ]; then
			"$driver" stop "$container"
			"$driver" rm "$container"
		fi
		count="$("$driver" volume ls --format "{{.Name}}" | grep -c "$volume")"
		if [ "$count" -gt 0 ]; then
			"$driver" volume rm "$volume"
		fi
	fi
done
