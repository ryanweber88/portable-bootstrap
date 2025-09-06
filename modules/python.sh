#!/usr/bin/env bash
# Python management for portable-bootstrap
# Handles Python 2 and Python 3 installation, pip setup, and version switching

# Source core utilities if not already loaded
if ! command -v log >/dev/null 2>&1; then
  # shellcheck source=core.sh
  . "$(dirname "${BASH_SOURCE[0]}")/core.sh"
fi

# Python version management
get_python2_version() {
  if command -v python2 >/dev/null 2>&1; then
    python2 --version 2>&1 | sed 's/Python //'
  else
    echo "not installed"
  fi
}

get_python3_version() {
  if command -v python3 >/dev/null 2>&1; then
    python3 --version 2>&1 | sed 's/Python //'
  else
    echo "not installed"
  fi
}

get_pip2_version() {
  if command -v pip2 >/dev/null 2>&1; then
    pip2 --version 2>/dev/null | awk '{print $2}' || echo "error"
  else
    echo "not installed"
  fi
}

get_pip3_version() {
  if command -v pip3 >/dev/null 2>&1; then
    pip3 --version 2>/dev/null | awk '{print $2}' || echo "error"
  else
    echo "not installed"
  fi
}

get_default_python_version() {
  if command -v python >/dev/null 2>&1; then
    python --version 2>&1 | sed 's/Python //'
  else
    echo "not configured"
  fi
}

# Installation functions
python_install_macos() {
  log "Installing Python on macOS..."
  
  # Install Python 3 via Homebrew (recommended)
  if ! command -v python3 >/dev/null 2>&1; then
    log "Installing Python 3 via Homebrew..."
    if command -v brew >/dev/null 2>&1; then
      brew install python@3.12
    else
      warn "Homebrew not found. Please install Homebrew first or install Python manually."
      return 1
    fi
  else
    ok "Python 3 is already installed"
  fi

  # Install Python 2 via pyenv with proper dependencies
  if ! command -v python2 >/dev/null 2>&1; then
    log "Installing Python 2 via pyenv (for legacy compatibility)..."
    
    # Install required dependencies first
    log "Installing Python build dependencies..."
    brew install openssl readline sqlite3 xz zlib tcl-tk
    
    if ! command -v pyenv >/dev/null 2>&1; then
      log "Installing pyenv..."
      brew install pyenv
      
      # Add pyenv to shell configuration
      local shell_rc
      if [[ "$SHELL" == *"zsh"* ]]; then
        shell_rc="$HOME/.zshrc"
      else
        shell_rc="$HOME/.bashrc"
      fi
      
      if ! grep -q 'pyenv init' "$shell_rc" 2>/dev/null; then
        echo 'export PYENV_ROOT="$HOME/.pyenv"' >> "$shell_rc"
        echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> "$shell_rc"
        echo 'eval "$(pyenv init -)"' >> "$shell_rc"
        log "Added pyenv initialization to $shell_rc"
      fi
      
      # Initialize pyenv for current session
      export PYENV_ROOT="$HOME/.pyenv"
      command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
      eval "$(pyenv init -)"
    fi
    
    # Set build environment variables for Python 2
    export LDFLAGS="-L$(brew --prefix openssl)/lib -L$(brew --prefix readline)/lib -L$(brew --prefix zlib)/lib -L$(brew --prefix sqlite)/lib"
    export CPPFLAGS="-I$(brew --prefix openssl)/include -I$(brew --prefix readline)/include -I$(brew --prefix zlib)/include -I$(brew --prefix sqlite)/include"
    export PKG_CONFIG_PATH="$(brew --prefix openssl)/lib/pkgconfig:$(brew --prefix readline)/lib/pkgconfig:$(brew --prefix zlib)/lib/pkgconfig:$(brew --prefix sqlite)/lib/pkgconfig"
    
    log "Installing Python 2.7.18 via pyenv with proper build flags..."
    if pyenv install 2.7.18; then
      # Create python2 symlink
      ensure_dir "$HOME/.local/bin"
      ln -sf "$HOME/.pyenv/versions/2.7.18/bin/python" "$HOME/.local/bin/python2"
      ln -sf "$HOME/.pyenv/versions/2.7.18/bin/pip" "$HOME/.local/bin/pip2" 2>/dev/null || true
      
      ok "Python 2.7.18 installed and available as python2"
    else
      warn "Python 2.7.18 installation failed. You can install it manually later with:"
      echo "  LDFLAGS=\"-L\$(brew --prefix openssl)/lib -L\$(brew --prefix readline)/lib -L\$(brew --prefix zlib)/lib\" \\"
      echo "  CPPFLAGS=\"-I\$(brew --prefix openssl)/include -I\$(brew --prefix readline)/include -I\$(brew --prefix zlib)/include\" \\"
      echo "  pyenv install 2.7.18"
    fi
  else
    ok "Python 2 is available"
  fi

  # Ensure pip3 is available
  python_setup_pip
}

python_install_linux() {
  log "Installing Python on Linux..."
  
  # Detect package manager and install Python
  if command -v apt-get >/dev/null 2>&1; then
    # Debian/Ubuntu
    log "Installing Python via apt..."
    sudo apt-get update
    sudo apt-get install -y python3 python3-pip python3-venv
    
    # Python 2 (if needed)
    if ! command -v python2 >/dev/null 2>&1; then
      log "Installing Python 2 (deprecated)..."
      sudo apt-get install -y python2 python2-dev
      # Install pip2 manually
      if ! command -v pip2 >/dev/null 2>&1; then
        curl https://bootstrap.pypa.io/pip/2.7/get-pip.py -o get-pip.py
        sudo python2 get-pip.py
        rm get-pip.py
      fi
    fi
    
  elif command -v yum >/dev/null 2>&1; then
    # RHEL/CentOS/Fedora
    log "Installing Python via yum..."
    sudo yum install -y python3 python3-pip
    
    # Python 2 (if available)
    if ! command -v python2 >/dev/null 2>&1; then
      sudo yum install -y python2 python2-pip || warn "Python 2 not available in repositories"
    fi
    
  elif command -v dnf >/dev/null 2>&1; then
    # Modern Fedora
    log "Installing Python via dnf..."
    sudo dnf install -y python3 python3-pip
    
    # Python 2 (if available)
    if ! command -v python2 >/dev/null 2>&1; then
      sudo dnf install -y python2 python2-pip || warn "Python 2 not available in repositories"
    fi
    
  else
    die "Unsupported Linux distribution. Please install Python manually."
  fi

  python_setup_pip
}

python_setup_pip() {
  log "Setting up pip..."
  
  # Ensure pip3 is working
  if command -v python3 >/dev/null 2>&1; then
    if ! command -v pip3 >/dev/null 2>&1; then
      log "Installing pip3..."
      python3 -m ensurepip --default-pip --user || {
        log "Downloading get-pip.py for Python 3..."
        curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
        python3 get-pip.py --user
        rm get-pip.py
      }
    fi
    
    # Upgrade pip3 with --user flag to avoid externally-managed-environment error
    log "Upgrading pip3..."
    if python3 -m pip install --upgrade pip --user 2>/dev/null; then
      ok "pip3 upgraded successfully"
    else
      log "pip3 upgrade skipped (externally managed environment)"
    fi
  fi
  
  # Setup pip2 if Python 2 is available
  if command -v python2 >/dev/null 2>&1; then
    if ! command -v pip2 >/dev/null 2>&1; then
      log "Installing pip2..."
      curl https://bootstrap.pypa.io/pip/2.7/get-pip.py -o get-pip.py
      python2 get-pip.py --user
      rm get-pip.py
    fi
    
    # Upgrade pip2
    log "Upgrading pip2..."
    if python2 -m pip install --upgrade pip --user 2>/dev/null; then
      ok "pip2 upgraded successfully"
    else
      log "pip2 upgrade skipped"
    fi
  fi
  
  # Install pipx for better Python package management
  if command -v brew >/dev/null 2>&1 && ! command -v pipx >/dev/null 2>&1; then
    log "Installing pipx for Python application management..."
    brew install pipx
    pipx ensurepath
  fi
  
  ok "Pip setup completed"
}

python_install() {
  log "Installing Python..."
  
  case "$(os_name)" in
    macos)
      python_install_macos
      ;;
    linux)
      python_install_linux
      ;;
    *)
      die "Unsupported operating system: $(os_name)"
      ;;
  esac
  
  ok "Python installation completed"
}

python_update() {
  log "Updating Python..."
  
  case "$(os_name)" in
    macos)
      if command -v brew >/dev/null 2>&1; then
        brew upgrade python@3.12
      else
        warn "Homebrew not found. Cannot update Python automatically."
      fi
      ;;
    linux)
      if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update && sudo apt-get upgrade -y python3 python3-pip
      elif command -v yum >/dev/null 2>&1; then
        sudo yum update -y python3 python3-pip
      elif command -v dnf >/dev/null 2>&1; then
        sudo dnf update -y python3 python3-pip
      else
        warn "Cannot determine package manager. Please update Python manually."
      fi
      ;;
    *)
      warn "Unsupported operating system for automatic updates"
      ;;
  esac
  
  # Update pip
  python_setup_pip
  
  ok "Python update completed"
}

python_set_default() {
  local version="$1"
  
  if [ -z "$version" ]; then
    die "Usage: pb python:set-default <2|3>"
  fi
  
  case "$version" in
    2)
      if ! command -v python2 >/dev/null 2>&1; then
        die "Python 2 is not installed"
      fi
      log "Setting Python 2 as default..."
      # Create symlink in ~/.local/bin
      ensure_dir "$HOME/.local/bin"
      ln -sf "$(command -v python2)" "$HOME/.local/bin/python"
      ok "Python 2 is now the default (python command)"
      ;;
    3)
      if ! command -v python3 >/dev/null 2>&1; then
        die "Python 3 is not installed"
      fi
      log "Setting Python 3 as default..."
      # Create symlink in ~/.local/bin
      ensure_dir "$HOME/.local/bin"
      ln -sf "$(command -v python3)" "$HOME/.local/bin/python"
      ok "Python 3 is now the default (python command)"
      ;;
    *)
      die "Invalid version. Use 2 or 3."
      ;;
  esac
}

python_status() {
  log "Python Status:"
  
  local python2_ver="$(get_python2_version)"
  local python3_ver="$(get_python3_version)"
  local pip2_ver="$(get_pip2_version)"
  local pip3_ver="$(get_pip3_version)"
  local default_ver="$(get_default_python_version)"
  
  echo
  echo "Python Versions:"
  if [ "$python2_ver" != "not installed" ]; then
    ok "Python 2: $python2_ver"
  else
    warn "Python 2: not installed"
  fi
  
  if [ "$python3_ver" != "not installed" ]; then
    ok "Python 3: $python3_ver"
  else
    warn "Python 3: not installed"
  fi
  
  echo
  echo "Pip Versions:"
  if [ "$pip2_ver" != "not installed" ]; then
    ok "pip2: $pip2_ver"
  else
    warn "pip2: not installed"
  fi
  
  if [ "$pip3_ver" != "not installed" ]; then
    ok "pip3: $pip3_ver"
  else
    warn "pip3: not installed"
  fi
  
  echo
  echo "Default Python:"
  if [ "$default_ver" != "not configured" ]; then
    ok "python command: $default_ver"
  else
    warn "python command: not configured"
    echo "  Use 'pb python:set-default <2|3>' to set a default version"
  fi
  
  # Show Python paths
  echo
  echo "Python Paths:"
  if command -v python2 >/dev/null 2>&1; then
    echo "  python2: $(command -v python2)"
  fi
  if command -v python3 >/dev/null 2>&1; then
    echo "  python3: $(command -v python3)"
  fi
  if command -v python >/dev/null 2>&1; then
    echo "  python:  $(command -v python)"
  fi
  
  # Show pip paths
  echo
  echo "Pip Paths:"
  if command -v pip2 >/dev/null 2>&1; then
    echo "  pip2: $(command -v pip2)"
  fi
  if command -v pip3 >/dev/null 2>&1; then
    echo "  pip3: $(command -v pip3)"
  fi
  if command -v pip >/dev/null 2>&1; then
    echo "  pip:  $(command -v pip)"
  fi
}
