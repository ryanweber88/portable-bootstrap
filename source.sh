#!/usr/bin/env bash
# pb - portable bootstrapper
# -----------------------------------------------------------------------------
# Features:
#  - One command: `pb install` to set up everything on macOS/Linux.
#  - Generates local files in ~/.portable-bootstrap (aliases, PATH, completions).
#  - Auto-wires shell startup files (bash, zsh) idempotently.
#  - Installs Git completion for bash & zsh; optional git prompt.
#  - Homebrew helpers for Apple Silicon vs Intel (install, switch env).
#  - Git default-branch safety: pre-push hook + GitHub branch protection (via gh).
#  - Repo scaffolding (`pb new-repo <name>`) with protections applied.
# -----------------------------------------------------------------------------
set -euo pipefail

PB_VERSION="0.1.0"
PB_HOME="${PB_HOME:-$HOME/.portable-bootstrap}"
PB_BIN_DIR="${PB_BIN_DIR:-$HOME/.local/bin}"
PB_NAME="${PB_NAME:-pb}"  # the command name to install
PB_COMPLETIONS_DIR="$PB_HOME/completions"

# URLs for completions (from upstream git repo)
GIT_COMPLETION_BASH_URL="https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash"
GIT_COMPLETION_ZSH_URL="https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.zsh"
GIT_PROMPT_URL="https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh"

log() { printf "➜ %s\n" "$*"; }
ok()  { printf "✅ %s\n" "$*"; }
err() { printf "❌ %s\n" "$*" >&2; }
die() { err "$*"; exit 1; }

is_macos() { [[ "$(uname -s)" == "Darwin" ]]; }
is_linux() { [[ "$(uname -s)" == "Linux" ]]; }
arch_name() { uname -m; }  # arm64 or x86_64 typically on macOS

ensure_dir() { mkdir -p "$1"; }

ensure_in_path() {
  case ":$PATH:" in *":$PB_BIN_DIR:"*) : ;; *) export PATH="$PB_BIN_DIR:$PATH" ;; esac
}

detect_shell_rc_files() {
  local files=()
  # Prefer user files; create if missing.
  if [ -n "${ZDOTDIR:-}" ] && [ -r "$ZDOTDIR/.zshrc" ]; then files+=("$ZDOTDIR/.zshrc"); fi
  [ -r "$HOME/.zshrc" ]  && files+=("$HOME/.zshrc")
  [ -r "$HOME/.bashrc" ] && files+=("$HOME/.bashrc")
  # If nothing exists, create bashrc as a safe default
  if [ ${#files[@]} -eq 0 ]; then
    touch "$HOME/.bashrc"
    files+=("$HOME/.bashrc")
  fi
  printf "%s\n" "${files[@]}"
}

append_once() {
  # append_once <file> <marker> <text>
  local file="$1" marker="$2" text="$3"
  touch "$file"
  if ! grep -Fq "$marker" "$file"; then
    printf "\n# %s\n%s\n" "$marker" "$text" >> "$file"
    ok "Updated $file"
  else
    log "Already present in $file ($marker)"
  fi
}

install_command() {
  ensure_dir "$PB_BIN_DIR"
  # If running from repo root, copy/symlink this script into PB_BIN_DIR as 'pb'
  local self="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "$0")"
  ln -sf "$self" "$PB_BIN_DIR/$PB_NAME"
  ensure_in_path
  command -v "$PB_NAME" >/dev/null || die "Failed to install $PB_NAME into PATH."
  ok "Installed command '$PB_NAME' into $PB_BIN_DIR"
}

generate_profile_files() {
  ensure_dir "$PB_HOME"

  # path.sh
  cat > "$PB_HOME/path.sh" <<'EOF'
# portable-bootstrap: PATH setup
# Add ~/.local/bin and Homebrew default prefixes if present (without duplicates)
case ":$PATH:" in *":$HOME/.local/bin:"*) : ;; *) export PATH="$HOME/.local/bin:$PATH";; esac
[ -d /opt/homebrew/bin ] && case ":$PATH:" in *":/opt/homebrew/bin:"*) : ;; *) export PATH="/opt/homebrew/bin:$PATH";; esac
[ -d /usr/local/bin ]   && case ":$PATH:" in *":/usr/local/bin:"*) : ;; *) export PATH="/usr/local/bin:$PATH";; esac
EOF

  # aliases.sh
  cat > "$PB_HOME/aliases.sh" <<'EOF'
# portable-bootstrap: common aliases & functions

# Git QoL
alias gs='git status'
alias st='git status'
alias gst='git status'
alias gl='git log --oneline --graph --decorate -n 30'
alias gb='git branch'
alias gco='git checkout'
alias gd='git diff'
alias diff='git diff'
alias gp='git push'
alias gpf='git push --force-with-lease'
EOF

  ok "Generated profile files in $PB_HOME"
}

# This is not working and it's because of the \n character in the middle of the src_lines variable.
# I need to find a way to make it work.
# The \n character is showing up directly in the output instead of being parsed as a newline.
# I need to find a way to make it work.
# I think I need to use printf instead of cat.
wire_shell_startup() {
  local marker="# portable-bootstrap"
  local src_lines
  src_lines="[ -f \"$PB_HOME/path.sh\" ] && . \"$PB_HOME/path.sh\"
[ -f \"$PB_HOME/aliases.sh\" ] && . \"$PB_HOME/aliases.sh\""
  local f
  while IFS= read -r f; do
    append_once "$f" "$marker" "$src_lines"
  done < <(detect_shell_rc_files)
}

download() {
  local url="$1" dest="$2"
  # curl or wget
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$dest"
  elif command -v wget >/dev/null 2>&1; then
    wget -q "$url" -O "$dest"
  else
    die "Neither curl nor wget found."
  fi
}

install_git_completions() {
  ensure_dir "$PB_COMPLETIONS_DIR"
  log "Installing Git completions into $PB_COMPLETIONS_DIR …"
  download "$GIT_COMPLETION_BASH_URL" "$PB_COMPLETIONS_DIR/git-completion.bash"
  download "$GIT_COMPLETION_ZSH_URL"  "$PB_COMPLETIONS_DIR/git-completion.zsh"
  download "$GIT_PROMPT_URL"          "$PB_COMPLETIONS_DIR/git-prompt.sh"

  # Wire for bash & zsh
  local marker_bash="# portable-bootstrap: git completion (bash)"
  local marker_zsh="# portable-bootstrap: git completion (zsh)"

  # bash
  if [ -r "$HOME/.bashrc" ]; then
    append_once "$HOME/.bashrc" "$marker_bash" "if [ -f \"$PB_COMPLETIONS_DIR/git-completion.bash\" ]; then . \"$PB_COMPLETIONS_DIR/git-completion.bash\"; fi"
  fi
  # zsh
  local zshrc="${ZDOTDIR:-$HOME}/.zshrc"
  [ -f "$zshrc" ] || touch "$zshrc"
  append_once "$zshrc" "$marker_zsh" "autoload -U compinit && compinit
if [ -f \"$PB_COMPLETIONS_DIR/git-completion.zsh\" ]; then . \"$PB_COMPLETIONS_DIR/git-completion.zsh\"; fi"

  ok "Git completions installed and wired."
}

require() { command -v "$1" >/dev/null 2>&1 || die "Missing required tool: $1"; }

new_repo() {
  local name="${1:-}"; [ -z "$name" ] && die "Usage: pb new-repo <name>"
  require gh; require git
  log "Creating new repo '$name' …"
  mkdir -p "$name" && cd "$name"
  git init
  cat > README.md <<EOF
# $name

Bootstrapped by portable-bootstrap.
EOF
  git add . && git commit -m "chore: initial commit via portable-bootstrap"
  gh repo create "$name" --public --source=. --remote=origin --push
  ok "Repo '$name' created."
}

# -------------------------- Homebrew helpers -------------------------------

brew_prefix_arm="/opt/homebrew"
brew_prefix_intel="/usr/local"

brew_detect() {
  if command -v brew >/dev/null 2>&1; then
    echo "brew in PATH: $(command -v brew)"
    brew --version | head -n1
  else
    echo "brew not found in PATH."
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
    # On Apple Silicon, install Intel Homebrew under Rosetta in /usr/local
    /usr/sbin/softwareupdate --install-rosetta --agree-to-license || true
    arch -x86_64 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ok "Intel Homebrew installed under Rosetta (likely at /usr/local)."
  else
    # On Intel mac, normal installer (still /usr/local)
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ok "Intel Homebrew installer completed."
  fi
}

brew_use_arm() {
  # Temporarily prefer arm brew in current shell
  if [ -x "$brew_prefix_arm/bin/brew" ]; then
    export PATH="$brew_prefix_arm/bin:$brew_prefix_arm/sbin:$PATH"
    ok "Using Apple Silicon Homebrew ($brew_prefix_arm)."
  else
    die "Apple Silicon Homebrew not found at $brew_prefix_arm"
  fi
}

brew_use_intel() {
  # Temporarily prefer intel brew in current shell
  if [ -x "$brew_prefix_intel/bin/brew" ]; then
    export PATH="$brew_prefix_intel/bin:$brew_prefix_intel/sbin:$PATH"
    ok "Using Intel Homebrew ($brew_prefix_intel)."
  else
    die "Intel Homebrew not found at $brew_prefix_intel"
  fi
}

# ------------------------------ Commands -----------------------------------

status() {
  echo "portable-bootstrap v$PB_VERSION"
  echo "Home:     $PB_HOME"
  echo "Bin dir:  $PB_BIN_DIR"
  echo "Command:  $PB_NAME ($(command -v "$PB_NAME" || echo 'not installed'))"
  echo "OS/Arch:  $(uname -s) / $(arch_name)"
  echo "Shell rc: $(detect_shell_rc_files | tr '\n' ' ')"
  echo "Brew:     $(brew_detect)"
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Repo:     $(git rev-parse --show-toplevel)"
    echo "Origin:   $(git remote get-url origin 2>/dev/null || echo 'none')"
    echo "Default:  $(git remote show origin 2>/dev/null | sed -n 's/ *HEAD branch: //p' || echo 'unknown')"
  else
    echo "Not in a git repo."
  fi
}

install() {
  install_command
  generate_profile_files
  wire_shell_startup
  install_git_completions
  ok "Install complete. Restart your shell to load aliases & completions."
}

uninstall() {
  log "Removing $PB_BIN_DIR/$PB_NAME and $PB_HOME entries…"
  rm -f "$PB_BIN_DIR/$PB_NAME"
  rm -rf "$PB_HOME"
  # Leave shell rc markers in place (non-destructive policy)
  ok "Uninstalled command & profile dir. You may remove rc lines manually if desired."
}

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
