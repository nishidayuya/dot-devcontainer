#!/bin/sh

set -eux

devcontainer --version
agy --version

devcontainer build
devcontainer up --workspace-folder . --remove-existing-container
exec devcontainer exec bash -eux -c '
  ruby --version
  gem install rake

  node --version
  npm install -g es6-map

  devcontainer --version

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

  # Check GitHub CLI connection
  gh version
  GH_TOKEN=dummy gh api https://github.com/nishidayuya/dot-devcontainer
'
