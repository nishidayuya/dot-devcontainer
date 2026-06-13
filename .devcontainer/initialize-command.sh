#!/bin/sh

set -eux

test -f .devcontainer/.env.additional ||
  touch .devcontainer/.env.additional
