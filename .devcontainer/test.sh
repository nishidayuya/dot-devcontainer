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

  check_connectivity "https://generativelanguage.googleapis.com/"
  check_connectivity "https://api.anthropic.com/"

  # Detect Gemini connection
  gemini_authed=false
  case "${GEMINI_API_KEY:-}" in
    ""|dummy)
      ;;
    *)
      gemini_authed=false
      ;;
  esac
  if test -f "$HOME/.gemini/oauth_creds.json" && ! grep -q "dummy" "$HOME/.gemini/oauth_creds.json"
  then
    gemini_authed=true
  fi

  gemini --version
  if test "$gemini_authed" = "true"
  then
    gemini --approval-mode plan --prompt "Hello, World!"
  else
    gemini --approval-mode plan --prompt "Hello, World!" || echo "Gemini prompt failed as expected with dummy credentials"
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
    echo "Claude authentication detected. Running print..."
    claude --no-session-persistence --print "Hello, World!" || echo "Claude print failed as expected with dummy credentials"
  else
    claude --no-session-persistence --print "Hello, World!"
  fi

  # Check GitHub CLI connection
  gh version
  GH_TOKEN=dummy gh api https://github.com/nishidayuya/dot-devcontainer
'
