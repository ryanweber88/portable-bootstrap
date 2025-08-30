#!/usr/bin/env bash
# Status command

status() {
  echo "portable-bootstrap v$PB_VERSION"
  echo "Home:     $PB_HOME"
  echo "Bin dir:  $PB_BIN_DIR"
  echo "Command:  $PB_NAME ($(command -v "$PB_NAME" || echo 'not installed'))"
  echo "OS/Arch:  $(uname -s) / $(arch_name)"
  printf "Shell rc: "
  detect_shell_rc_files | tr '\n' ' '; echo
  printf "Brew:     "
  brew_detect
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Repo:     $(git rev-parse --show-toplevel)"
    echo "Origin:   $(git remote get-url origin 2>/dev/null || echo 'none')"
    echo "Default:  $(git remote show origin 2>/dev/null | sed -n 's/ *HEAD branch: //p' || echo 'unknown')"
  else
    echo "Not in a git repo."
  fi
}
