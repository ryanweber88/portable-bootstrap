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

# Source all modules - check both development and installed locations
if [ -d "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/modules" ]; then
  # Development mode - modules are in ./modules/
  for f in "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/modules/*.sh; do
    . "$f"
  done
elif [ -d "$PB_HOME/modules" ]; then
  # Installed mode - modules are in $PB_HOME/modules/
  for f in "$PB_HOME/modules"/*.sh; do
    . "$f"
  done
else
  die "Cannot find portable-bootstrap modules"
fi

usage() {
  cat <<USAGE
pb v$PB_VERSION - portable bootstrap toolkit

Commands:
  install                 Install command, generate profiles, wire shell, git completions, node stack
  status                  Show environment info and git repo/default-branch if present
  new-repo <name>         Create new repo, push to GitHub
  brew:install-arm        Install Apple Silicon Homebrew (macOS)
  brew:install-intel      Install Intel/Rosetta Homebrew (macOS)
  brew:use-arm            Prefer Apple Silicon Homebrew in current shell
  brew:use-intel          Prefer Intel Homebrew in current shell
  node:install            Install NVM and latest Node.js/npm
  node:status             Show Node.js/npm/NVM versions and status
  terraform:install       Install Terraform
  terraform:update        Update Terraform to latest version
  terraform:init [dir]    Initialize Terraform workspace (defaults to current dir)
  terraform:validate [dir] Validate Terraform configuration
  terraform:plan [dir]    Run terraform plan
  terraform:apply [dir]   Run terraform apply
  aws:install             Install AWS CLI
  aws:update              Update AWS CLI to latest version
  aws:configure           Configure AWS CLI interactively
  aws:configure-profile <name> Configure AWS CLI profile
  aws:list-profiles       List all AWS CLI profiles
  aws:status              Show AWS CLI status and current identity
  aws:set-region <region> [profile] Set AWS region
  aws:sso-login [profile] Perform SSO login for AWS profile
  python:install          Install Python 2 and Python 3 with pip
  python:update           Update Python and pip to latest versions
  python:set-default <2|3> Set default Python version for 'python' command
  python:status           Show Python and pip versions and status
  uninstall               Remove pb command and ~/.portable-bootstrap
  help                    Show this help message
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
  node:install)       install_node_stack ;;
  node:status)        node_status ;;
  terraform:install)  terraform_install ;;
  terraform:update)   terraform_update ;;
  terraform:init)     terraform_init_workspace "$@" ;;
  terraform:validate) terraform_validate_config "$@" ;;
  terraform:plan)     terraform_plan "$@" ;;
  terraform:apply)    terraform_apply "$@" ;;
  aws:install)        aws_install ;;
  aws:update)         aws_update ;;
  aws:configure)      aws_configure_interactive ;;
  aws:configure-profile) aws_configure_profile "$@" ;;
  aws:list-profiles)  aws_list_profiles ;;
  aws:status)         aws_status ;;
  aws:set-region)     aws_set_region "$@" ;;
  aws:sso-login)      aws_login_sso "$@" ;;
  python:install)     python_install ;;
  python:update)      python_update ;;
  python:set-default) python_set_default "$@" ;;
  python:status)      python_status ;;
  uninstall)          uninstall ;;
  help|--help|-h)     usage ;;
  *)                  die "Unknown command: $cmd (try 'help')" ;;
esac
