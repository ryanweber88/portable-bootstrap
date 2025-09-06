#!/usr/bin/env bash
# Installation, wiring, and profile generation

detect_shell_rc_files() {
  local files=()
  # Prefer user files; create if missing.
  if [ -n "${ZDOTDIR:-}" ] && [ -r "$ZDOTDIR/.zshrc" ]; then files+=("$ZDOTDIR/.zshrc"); fi
  [ -r "$HOME/.zshrc" ] && files+=("$HOME/.zshrc")
  [ -r "$HOME/.bashrc" ] && files+=("$HOME/.bashrc")
  # If nothing exists, create bashrc as a safe default
  if [ ${#files[@]} -eq 0 ]; then
    touch "$HOME/.bashrc"
    files+=("$HOME/.bashrc")
  fi
  printf "%s\n" "${files[@]}"
}

install_command() {
  ensure_dir "$PB_BIN_DIR"
  ensure_dir "$PB_HOME/modules"

  # Copy the main script
  cp "$PB_SCRIPT_PATH" "$PB_BIN_DIR/$PB_NAME"
  chmod +x "$PB_BIN_DIR/$PB_NAME"

  # Copy all modules to the home directory
  local modules_source_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  cp -f "$modules_source_dir"/*.sh "$PB_HOME/modules/"

  ensure_in_path
  command -v "$PB_NAME" >/dev/null || die "Failed to install $PB_NAME into PATH."
  ok "Installed command '$PB_NAME' into $PB_BIN_DIR with modules in $PB_HOME/modules"
}

generate_profile_files() {
  ensure_dir "$PB_HOME"

  # Copy canonical profiles into PB_HOME
  local profile_source_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../profiles && pwd)"
  local aliases_updated=false
  local path_updated=false

  # Check if aliases.sh needs updating (source is newer or destination doesn't exist)
  if [ ! -f "$PB_HOME/aliases.sh" ] || [ "$profile_source_dir/aliases.sh" -nt "$PB_HOME/aliases.sh" ]; then
    cp -f "$profile_source_dir/aliases.sh" "$PB_HOME/aliases.sh"
    aliases_updated=true
    log "Updated aliases.sh"
  fi

  # Check if path.sh needs updating (source is newer or destination doesn't exist)
  if [ ! -f "$PB_HOME/path.sh" ] || [ "$profile_source_dir/path.sh" -nt "$PB_HOME/path.sh" ]; then
    cp -f "$profile_source_dir/path.sh" "$PB_HOME/path.sh"
    path_updated=true
    log "Updated path.sh"
  fi

  if [ "$aliases_updated" = true ] || [ "$path_updated" = true ]; then
    ok "Profile files updated in $PB_HOME"
    log "Restart your shell or run 'source ~/.zshrc' to load new aliases"
  else
    log "Profile files are up to date"
  fi
}

wire_shell_startup() {
  local marker="# portable-bootstrap: main"
  while IFS= read -r f; do
    touch "$f"
    if ! grep -Fq "$marker" "$f"; then
      {
        printf "\n%s\n" "$marker"
        printf '[ -f "%s/path.sh" ] && . "%s/path.sh"\n' "$PB_HOME" "$PB_HOME"
        printf '[ -f "%s/aliases.sh" ] && . "%s/aliases.sh"\n' "$PB_HOME" "$PB_HOME"
      } >> "$f"
      ok "Updated $f"
    else
      log "Already present in $f ($marker)"
    fi
  done < <(detect_shell_rc_files)
}

install_git_completions() {
  ensure_dir "$PB_COMPLETIONS_DIR"
  ensure_dir "$PB_ZFUNCDIR"

  log "Installing Git completions into $PB_COMPLETIONS_DIR …"
  download "$GIT_COMPLETION_BASH_URL" "$PB_COMPLETIONS_DIR/git-completion.bash"
  download "$GIT_COMPLETION_ZSH_URL" "$PB_COMPLETIONS_DIR/git-completion.zsh"
  download "$GIT_PROMPT_URL" "$PB_COMPLETIONS_DIR/git-prompt.sh"

  # Bash: source bash completion
  if [ -r "$HOME/.bashrc" ]; then
    append_once "$HOME/.bashrc" "# portable-bootstrap: git completion (bash)" \
'if [ -f "'"$PB_COMPLETIONS_DIR"'/git-completion.bash" ]; then . "'"$PB_COMPLETIONS_DIR"'/git-completion.bash"; fi'
  fi

  # Zsh: autoload _git via fpath and configure bash completion path
  cp -f "$PB_COMPLETIONS_DIR/git-completion.zsh" "$PB_ZFUNCDIR/_git"
  local zshrc="${ZDOTDIR:-$HOME}/.zshrc"
  [ -f "$zshrc" ] || touch "$zshrc"
  append_once "$zshrc" "# portable-bootstrap: zfunc path" 'fpath=("'"$PB_ZFUNCDIR"'" $fpath)'
  append_once "$zshrc" "# portable-bootstrap: git completion script path" 'zstyle ":completion:*:*:git:*" script "'"$PB_COMPLETIONS_DIR"'/git-completion.bash"'
  append_once "$zshrc" "# portable-bootstrap: compinit" 'autoload -Uz compinit; compinit -i'

  ok "Git completions installed and wired."
}

install() {
  install_command
  generate_profile_files
  wire_shell_startup
  install_git_completions

  # Install Node.js stack if not already present
  if ! has_node || ! has_npm || ! has_nvm; then
    log "Setting up Node.js development environment..."
    install_node_stack
  else
    log "Node.js stack already available - Node: $(get_node_version), npm: $(get_npm_version), NVM: $(get_nvm_version)"
  fi

  # Install Terraform if not already present
  if ! command -v terraform >/dev/null 2>&1; then
    log "Installing Terraform..."
    terraform_install
  else
    log "Terraform already available - $(terraform_detect)"
  fi

  # Install AWS CLI if not already present
  if ! command -v aws >/dev/null 2>&1; then
    log "Installing AWS CLI..."
    aws_install
  else
    log "AWS CLI already available - $(aws_detect)"
  fi

  # Install Python 2 and 3 if not already present
  log "Setting up Python environment..."
  python_install

  ok "Install complete. Open a NEW terminal to load aliases, completions & development environment."
}

uninstall() {
  log "Removing $PB_BIN_DIR/$PB_NAME and $PB_HOME entries…"
  rm -f "$PB_BIN_DIR/$PB_NAME"
  rm -rf "$PB_HOME"
  ok "Uninstalled command & profile dir. You may remove rc lines manually if desired."
}
