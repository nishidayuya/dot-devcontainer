#!/bin/sh

set -eux

devcontainer --version
gemini --version

devcontainer build
devcontainer up --workspace-folder . --remove-existing-container
exec devcontainer exec bash -eux -c '
  ruby --version
  gem install rake

  node --version
  npm install -g es6-map

  devcontainer --version

  gemini --version
  gemini --prompt "Hello, World!"

  claude --version
  claude --no-session-persistence --print "Hello, World!"

  # Check GitHub CLI authentication
  gh auth status
'
