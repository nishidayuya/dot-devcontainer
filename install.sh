#!/bin/sh

set -eu

REF="${DOT_DEVCONTAINER_REF:-main}"
TARBALL_URL="https://github.com/nishidayuya/dot-devcontainer/archive/${REF}.tar.gz"

echo "Installing .devcontainer files from ${REF}..."

# Remove existing .devcontainer directory without checking
rm -rf .devcontainer

echo "Downloading and extracting..."
# GitHub's tarball structure: dot-devcontainer-<ref>/.devcontainer/
# Use --strip-components=1 to remove the top-level directory prefix.
curl -f -sL "${TARBALL_URL}" | tar -xz --strip-components=1 "dot-devcontainer-${REF}/.devcontainer"

echo "Done!"
