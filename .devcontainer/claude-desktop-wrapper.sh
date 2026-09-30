#!/bin/sh

# Installed as /usr/local/bin/claude-desktop, in front of the /usr/bin one that
# the package provides.
#
# Claude Desktop ships an Electron build without the --ozone-platform-hint
# switch, so it always starts on X11 and gives up with "Missing X server or
# $DISPLAY": there is no X server in this container, and no XWayland either,
# only the Wayland socket of the host that devcontainer.json mounts. Selecting
# the Wayland backend is therefore left to this wrapper.
#
# The switch is added only when WAYLAND_DISPLAY names something, so that
# removing the Wayland mount from devcontainer.json leaves the application
# behaving the way the package intends.

set -eu

if [ -n "${WAYLAND_DISPLAY:-}" ]; then
  set -- --ozone-platform=wayland "$@"
fi

exec /usr/bin/claude-desktop "$@"
