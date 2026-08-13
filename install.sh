#!/bin/sh

set -eux

REF="${DOT_DEVCONTAINER_REF:-main}"
TARBALL_URL="https://github.com/nishidayuya/dot-devcontainer/archive/${REF}.tar.gz"

echo "Installing .devcontainer files from ${REF}..."

echo "Downloading and extracting..."
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/dot-devcontainer.XXXXXX")"
trap 'rm -rf "${tmp_dir}"' EXIT

# GitHub's tarball has a single top-level directory whose name depends on the
# ref (e.g. tag "v1.0.0" becomes "dot-devcontainer-1.0.0"), so strip it off
# instead of naming it. Picking the member with a wildcard is not portable:
# GNU tar needs --wildcards, which macOS's bsdtar rejects outright.
curl -f -sL "${TARBALL_URL}" | tar -xz --strip-components=1 -C "${tmp_dir}"

# Replace the existing .devcontainer directory only after the download
# succeeded, so a network failure does not leave the project without one.
rm -rf .devcontainer
mv "${tmp_dir}/.devcontainer" .devcontainer

echo "Done!"
