#!/usr/bin/env bash
# Homebrew helpers

brew_prefix_arm="/opt/homebrew"
brew_prefix_intel="/usr/local"

brew_detect() {
  if command -v brew >/dev/null 2>&1; then
    brew --version | head -n1
  else
    echo "brew not found"
  fi
}

brew_install_arm() {
  is_macos || die "Homebrew install helpers are for macOS."
  if [ "$(arch_name)" != "arm64" ]; then
    log "Installing Apple Silicon Homebrew on non-arm64 may not be relevant."
  fi
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ok "Apple Silicon Homebrew installer completed (check output for next steps)."
}

brew_install_intel() {
  is_macos || die "Homebrew install helpers are for macOS."
  if [ "$(arch_name)" = "arm64" ]; then
    /usr/sbin/softwareupdate --install-rosetta --agree-to-license || true
    arch -x86_64 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ok "Intel Homebrew installed under Rosetta (likely at /usr/local)."
  else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ok "Intel Homebrew installer completed."
  fi
}

brew_use_arm() {
  if [ -x "$brew_prefix_arm/bin/brew" ]; then
    export PATH="$brew_prefix_arm/bin:$brew_prefix_arm/sbin:$PATH"
    ok "Using Apple Silicon Homebrew ($brew_prefix_arm)."
  else
    die "Apple Silicon Homebrew not found at $brew_prefix_arm"
  fi
}

brew_use_intel() {
  if [ -x "$brew_prefix_intel/bin/brew" ]; then
    export PATH="$brew_prefix_intel/bin:$brew_prefix_intel/sbin:$PATH"
    ok "Using Intel Homebrew ($brew_prefix_intel)."
  else
    die "Intel Homebrew not found at $brew_prefix_intel"
  fi
}
