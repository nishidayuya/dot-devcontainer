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
curl -fsSL --retry 3 --retry-all-errors "${TARBALL_URL}" | tar -xz --strip-components=1 -C "${tmp_dir}"

# .env.additional is not shipped at all and holds this project's environment,
# such as GH_TOKEN, so carry it over into the new tree. Copying rather than
# moving leaves the old tree intact until the swap below.
if [ -f .devcontainer/.env.additional ]; then
  cp -p .devcontainer/.env.additional "${tmp_dir}/.devcontainer/.env.additional"
fi
# allow_hosts.d ships empty and holds the hosts this project chose, so carry
# them over the same way.
if [ -d .devcontainer/allow_hosts.d ]; then
  cp -Rp .devcontainer/allow_hosts.d/. "${tmp_dir}/.devcontainer/allow_hosts.d/"
fi

# Replace the existing .devcontainer directory only after the download
# succeeded, so a network failure does not leave the project without one.
rm -rf .devcontainer
mv "${tmp_dir}/.devcontainer" .devcontainer

echo "Done!"
