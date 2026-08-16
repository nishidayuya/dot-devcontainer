#!/bin/bash

# Checks that run inside the dev container. Both .devcontainer/test-devpod.sh
# and .devcontainer/test-devcontainer.sh run this same script, so that the two
# CLIs are held to the same standard.

set -eux

ruby --version
gem install rake

# Node.js is not installed in the image anymore (the Dev Container CLI
# standalone installer bundles its own runtime), so install it here to verify
# that mise can fetch it and that npm works through the firewall.
mise use -g node@24
node --version
npm install -g es6-map

# Rust is not installed in the image either (see the commented-out lines in the
# Dockerfile), so install it here to verify that mise can bootstrap rustup and
# that cargo can reach the crates.io registry through the firewall.
mise use -g rust@latest
rustc --version
cargo --version
rust_test_dir="$(mktemp -d)"
cargo init --vcs none --name dot_devcontainer_rust_test "$rust_test_dir"
cd "$rust_test_dir"
cargo add anyhow
cargo build
cd -

# Git comes from apt in the image (see the commented-out lines in the
# Dockerfile), so install it here to verify that mise can build Git from source
# with the asdf-git plugin through the firewall. This has to run after the Rust
# step above: Git 2.55 and later build libgitcore with cargo unless NO_RUST is
# set.
#
# Install Git's extra build dependencies first, the same way the commented-out
# Dockerfile lines do.
sudo apt-get update
sudo env -- DEBIAN_FRONTEND=noninteractive \
  apt-get -y install --no-install-recommends \
  gettext \
  libcurl4-openssl-dev \
  libexpat1-dev
mise plugin add git https://github.com/nishidayuya/asdf-git
mise use -g git@latest
# The mise shims directory comes first in PATH, so plain "git" must now resolve
# to the mise-managed build instead of /usr/bin/git. hash -r drops any path this
# shell already remembered for git.
hash -r
git --version
test "$(git --exec-path)" = "$(mise where git)/libexec/git-core"
# git-subtree is one of the contrib commands the asdf-git plugin installs by
# default, so its presence proves the contrib build step ran too.
test -x "$(git --exec-path)/git-subtree"

devcontainer --version
devpod version

# Verify connectivity to AI API endpoints (Firewall test)
# Even with dummy keys, these should connect (getting 401/403/404 instead of timeout/refusal)
check_connectivity() {
  local url=$1
  echo "Testing connectivity to $url..."
  if curl -I -s --max-time 10 "$url" > /dev/null; then
    echo "Connectivity to $url: OK"
  else
    local exit_code=$?
    echo "Connectivity to $url: FAILED (curl exit code: $exit_code)"
    return 1
  fi
}

check_connectivity "https://antigravity.google/"
check_connectivity "https://api.anthropic.com/"

# Detect Antigravity connection
# Antigravity CLI authenticates via browser-based Google sign-in and stores
# its credentials under ~/.gemini. "agy models" requires a valid login, so we
# use it to probe whether the CLI is authenticated.
agy_authed=false
if agy models >/dev/null 2>&1
then
  agy_authed=true
fi

agy --version
if test "$agy_authed" = "true"
then
  agy --print "Hello, World!"
else
  agy --print --print-timeout 30s "Hello, World!" || echo "Antigravity prompt failed as expected without credentials"
fi

# Detect Claude connection
claude_authed=false
case "${ANTHROPIC_API_KEY:-}" in
  ""|dummy)
    ;;
  *)
    claude_authed=false
    ;;
esac
if test -f "$HOME/.claude/.credentials.json" && ! grep -q "dummy" "$HOME/.claude/.credentials.json"
then
  claude_authed=true
fi

claude --version
if test "$claude_authed" = true
then
  claude --no-session-persistence --print "Hello, World!"
else
  claude --no-session-persistence --print "Hello, World!" || echo "Claude prompt failed as expected with dummy credentials"
fi

# Claude Desktop is a GUI application, so there is nothing to prompt here.
# Check that the package is installed and that it gets far enough to print its
# version: that already exercises the Chromium zygote, which is where an
# Electron application in a container usually fails.
dpkg-query -W -f='${Package} ${Version}\n' claude-desktop
# The wrapper that puts it on Wayland has to be the one that PATH finds
test "$(command -v claude-desktop)" = /usr/local/bin/claude-desktop
claude-desktop --version

# Everything Claude Desktop draws on has to be reachable from the container:
# the Wayland socket bind-mounted from the host, and the session bus that
# post_start_command.d/50-dbus-session starts.
test -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"
test "$(stat -c '%a' "$XDG_RUNTIME_DIR")" = 700
test "$(stat -c '%u' "$XDG_RUNTIME_DIR")" = "$(id -u)"
dbus-send --dest=org.freedesktop.DBus --print-reply \
  /org/freedesktop/DBus org.freedesktop.DBus.GetId

# The --shm-size in runArgs, without which Chromium renderers die on Docker's
# 64 MB default
test "$(df -m --output=size /dev/shm | tail -n 1)" -ge 1024

# Check GitHub CLI connection
gh version
GH_TOKEN=dummy gh api https://github.com/nishidayuya/dot-devcontainer
