#!/bin/bash

set -eu

# Hosts to scan for SSH host keys.
HOSTS="github.com"

KNOWN_HOSTS="${HOME}/.ssh/known_hosts"

mkdir -p "${HOME}/.ssh"
chmod 700 "${HOME}/.ssh"

touch "${KNOWN_HOSTS}"
chmod 600 "${KNOWN_HOSTS}"

for host in ${HOSTS}; do
  echo "Scanning SSH host keys for ${host}..."

  # Fetch the current host keys.
  keys=$(ssh-keyscan "${host}")

  # Remove existing entries for this host to avoid duplicates, then append the
  # freshly fetched keys.
  ssh-keygen -R "${host}" -f "${KNOWN_HOSTS}" >/dev/null 2>&1 || true
  echo "${keys}" >> "${KNOWN_HOSTS}"

  echo "Added SSH host keys for ${host} to ${KNOWN_HOSTS}."
done
