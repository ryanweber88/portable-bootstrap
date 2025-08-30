#!/usr/bin/env bash
# pb - portable bootstrapper
# -----------------------------------------------------------------------------
# This script is a lightweight dispatcher. All logic is in ./modules/*.sh
# -----------------------------------------------------------------------------
set -euo pipefail

# Store the real path to this script, resolving symlinks
PB_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

PB_VERSION="0.2.0"
PB_HOME="${PB_HOME:-$HOME/.portable-bootstrap}"
PB_BIN_DIR="${PB_BIN_DIR:-$HOME/.local/bin}"
PB_NAME="${PB_NAME:-pb}"  # the command name to install
PB_COMPLETIONS_DIR="$PB_HOME/completions"
PB_ZFUNCDIR="$PB_COMPLETIONS_DIR/zfunc"   # for zsh autoloaded functions

# Source all modules
for f in "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/modules/*.sh; do
  . "$f"
done

usage() {
  cat <<USAGE
pb v$PB_VERSION - portable bootstrap toolkit

Commands:
  install                 Install command, generate profiles, wire shell, git completions
  status                  Show environment info and git repo/default-branch if present
  new-repo <name>         Create new repo, push to GitHub
  brew:install-arm        Install Apple Silicon Homebrew (macOS)
  brew:install-intel      Install Intel/Rosetta Homebrew (macOS)
  brew:use-arm            Prefer Apple Silicon Homebrew in current shell
  brew:use-intel          Prefer Intel Homebrew in current shell
  uninstall               Remove installed command and profile directory
  help                    Show this help
USAGE
}

cmd="${1:-help}"; shift || true
case "$cmd" in
  install)            install ;;
  status)             status ;;
  new-repo)           new_repo "$@" ;;
  brew:install-arm)   brew_install_arm ;;
  brew:install-intel) brew_install_intel ;;
  brew:use-arm)       brew_use_arm ;;
  brew:use-intel)     brew_use_intel ;;
  uninstall)          uninstall ;;
  help|--help|-h)     usage ;;
  *)                  die "Unknown command: $cmd (try 'help')" ;;
esac
