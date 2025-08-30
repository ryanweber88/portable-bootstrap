#!/usr/bin/env bash
# Core utility functions

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

download() {
  local url="$1" dest="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$dest"
  elif command -v wget >/dev/null 2>&1; then
    wget -q "$url" -O "$dest"
  else
    die "Neither curl nor wget found."
  fi
}

require() { command -v "$1" >/dev/null 2>&1 || die "Missing required tool: $1"; }

append_once() {
  # append_once <file> <marker> <text>  (single-line only)
  local file="$1" marker="$2" text="$3"
  touch "$file"
  if ! grep -Fq "$marker" "$file"; then
    printf "\n# %s\n%s\n" "$marker" "$text" >> "$file"
    ok "Updated $file"
  else
    log "Already present in $file ($marker)"
  fi
}
