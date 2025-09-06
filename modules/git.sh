#!/usr/bin/env bash
# Git and repository features

# Upstream completion sources
GIT_COMPLETION_BASH_URL="https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash"
GIT_COMPLETION_ZSH_URL="https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.zsh"
GIT_PROMPT_URL="https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh"

new_repo() {
  local name="${1:-}"; [ -z "$name" ] && die "Usage: pb new-repo <name>"
  require gh; require git
  log "Creating new repo '$name' …"
  mkdir -p "$name" && cd "$name" || return
  git init
  cat > README.md <<EOF
# $name

Bootstrapped by portable-bootstrap.
EOF
  git add . && git commit -m "chore: initial commit via portable-bootstrap"
  gh repo create "$name" --public --source=. --remote=origin --push
  ok "Repo '$name' created."
}
