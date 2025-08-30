# portable-bootstrap: PATH setup
# Add ~/.local/bin and Homebrew default prefixes if present (without duplicates)
case ":$PATH:" in *":$HOME/.local/bin:"*) : ;; *) export PATH="$HOME/.local/bin:$PATH";; esac
[ -d /opt/homebrew/bin ] && case ":$PATH:" in *":/opt/homebrew/bin:"*) : ;; *) export PATH="/opt/homebrew/bin:$PATH";; esac
[ -d /usr/local/bin ]   && case ":$PATH:" in *":/usr/local/bin:"*) : ;; *) export PATH="/usr/local/bin:$PATH";; esac
