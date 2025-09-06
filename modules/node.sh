#!/usr/bin/env bash
# Node.js, npm, and nvm setup

# NVM installation URL
NVM_INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh"

# Detection functions
has_node() { command -v node >/dev/null 2>&1; }
has_npm() { command -v npm >/dev/null 2>&1; }
has_nvm() { command -v nvm >/dev/null 2>&1 || [ -s "$HOME/.nvm/nvm.sh" ]; }

get_node_version() {
  if has_node; then
    node --version 2>/dev/null | sed 's/^v//'
  else
    echo "not installed"
  fi
}

get_npm_version() {
  if has_npm; then
    npm --version 2>/dev/null
  else
    echo "not installed"
  fi
}

get_nvm_version() {
  if has_nvm; then
    if command -v nvm >/dev/null 2>&1; then
      nvm --version 2>/dev/null
    elif [ -s "$HOME/.nvm/nvm.sh" ]; then
      # Source nvm and get version
      . "$HOME/.nvm/nvm.sh" && nvm --version 2>/dev/null || echo "installed (version unknown)"
    fi
  else
    echo "not installed"
  fi
}

install_nvm() {
  if has_nvm; then
    log "NVM already installed ($(get_nvm_version))"
    return 0
  fi

  log "Installing NVM..."
  if ! download "$NVM_INSTALL_URL" "/tmp/nvm-install.sh"; then
    die "Failed to download NVM installer"
  fi

  # Run the NVM installer
  bash /tmp/nvm-install.sh
  rm -f /tmp/nvm-install.sh

  # Source nvm for this session
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

  if has_nvm; then
    ok "NVM installed successfully ($(get_nvm_version))"
  else
    die "NVM installation failed"
  fi
}

install_latest_node() {
  # Ensure NVM is available
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

  if ! has_nvm; then
    die "NVM is not available. Please install NVM first."
  fi

  log "Installing latest LTS version of Node.js..."
  nvm install --lts
  nvm use --lts
  nvm alias default lts/*

  if has_node && has_npm; then
    ok "Node.js $(get_node_version) and npm $(get_npm_version) installed successfully"
  else
    die "Node.js installation failed"
  fi
}

setup_node_environment() {
  # Add NVM sourcing to shell profiles if not already present
  local nvm_marker="# portable-bootstrap: nvm"
  local nvm_source_lines='
# Load NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"'

  while IFS= read -r f; do
    if ! grep -Fq "$nvm_marker" "$f"; then
      {
        printf "\n%s\n" "$nvm_marker"
        printf "%s\n" "$nvm_source_lines"
      } >> "$f"
      ok "Added NVM sourcing to $f"
    else
      log "NVM sourcing already present in $f"
    fi
  done < <(detect_shell_rc_files)
}

node_status() {
  log "Node.js Environment Status:"
  printf "  Node.js: %s\n" "$(get_node_version)"
  printf "  npm:     %s\n" "$(get_npm_version)"
  printf "  NVM:     %s\n" "$(get_nvm_version)"

  if has_nvm; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    if command -v nvm >/dev/null 2>&1; then
      printf "  NVM current: %s\n" "$(nvm current 2>/dev/null || echo 'none')"
      printf "  NVM default: %s\n" "$(nvm alias default 2>/dev/null || echo 'none')"
    fi
  fi
}

install_node_stack() {
  log "Setting up Node.js development environment..."

  # Check current status
  local node_ver="$(get_node_version)"
  local npm_ver="$(get_npm_version)"
  local nvm_ver="$(get_nvm_version)"

  log "Current versions - Node: $node_ver, npm: $npm_ver, NVM: $nvm_ver"

  # Install NVM if not present
  if ! has_nvm; then
    install_nvm
  else
    log "NVM already available ($nvm_ver)"
  fi

  # Install latest Node.js if not present or if installed outside NVM
  if ! has_node; then
    install_latest_node
  else
    # Check if Node was installed via NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

    if command -v nvm >/dev/null 2>&1; then
      local current_node="$(nvm current 2>/dev/null)"
      if [[ "$current_node" == "system" ]] || [[ "$current_node" == "none" ]]; then
        log "Node.js found but not managed by NVM. Installing latest LTS via NVM..."
        install_latest_node
      else
        log "Node.js already managed by NVM ($current_node)"
      fi
    else
      log "Node.js found ($node_ver) but NVM not available in current session"
    fi
  fi

  # Setup shell environment
  setup_node_environment

  ok "Node.js stack setup complete!"
  node_status
}
