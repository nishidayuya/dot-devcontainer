#!/bin/sh

set -eux

devcontainer --version
gemini --version

devcontainer build
devcontainer up --workspace-folder . --remove-existing-container
exec devcontainer exec bash -eux -c '
  devcontainer --version
  gemini --version
  gemini --prompt "Hello, World!"
'
