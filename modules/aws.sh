#!/usr/bin/env bash
# AWS CLI installation and management

aws_detect() {
  if command -v aws >/dev/null 2>&1; then
    aws --version 2>&1 | head -n1
  else
    echo "aws cli not found"
  fi
}

aws_install() {
  log "Installing AWS CLI..."

  if is_macos; then
    aws_install_macos
  elif is_linux; then
    aws_install_linux
  else
    die "Unsupported platform for AWS CLI installation"
  fi
}

aws_install_macos() {
  if command -v brew >/dev/null 2>&1; then
    log "Installing AWS CLI via Homebrew..."
    brew install awscli
    ok "AWS CLI installed via Homebrew"
  else
    log "Homebrew not found, installing AWS CLI manually..."
    aws_install_manual_macos
  fi
}

aws_install_manual_macos() {
  local arch_suffix
  case "$(arch_name)" in
    arm64) arch_suffix="arm64" ;;
    x86_64) arch_suffix="x86_64" ;;
    *) die "Unsupported architecture: $(arch_name)" ;;
  esac

  local url="https://awscli.amazonaws.com/AWSCLIV2-${arch_suffix}.pkg"
  local temp_dir="/tmp/aws-cli-install"

  ensure_dir "$temp_dir"

  log "Downloading AWS CLI installer for macOS ${arch_suffix}..."
  download "$url" "$temp_dir/AWSCLIV2.pkg"

  log "Installing AWS CLI (requires sudo)..."
  sudo installer -pkg "$temp_dir/AWSCLIV2.pkg" -target /

  rm -rf "$temp_dir"
  ok "AWS CLI installed system-wide"
}

aws_install_linux() {
  local arch_suffix
  case "$(arch_name)" in
    x86_64) arch_suffix="x86_64" ;;
    aarch64|arm64) arch_suffix="aarch64" ;;
    *) die "Unsupported architecture: $(arch_name)" ;;
  esac

  local url="https://awscli.amazonaws.com/awscli-exe-linux-${arch_suffix}.zip"
  local temp_dir="/tmp/aws-cli-install"

  ensure_dir "$temp_dir"

  log "Downloading AWS CLI for Linux ${arch_suffix}..."
  download "$url" "$temp_dir/awscliv2.zip"

  log "Extracting AWS CLI..."
  cd "$temp_dir" || die "Failed to change to temp directory"
  unzip -q awscliv2.zip

  log "Installing AWS CLI (may require sudo for system-wide install)..."
  if [ -w "/usr/local/bin" ]; then
    ./aws/install
  else
    sudo ./aws/install
  fi

  rm -rf "$temp_dir"
  ok "AWS CLI installed"
}

aws_update() {
  log "Updating AWS CLI..."

  if is_macos && command -v brew >/dev/null 2>&1; then
    brew upgrade awscli
    ok "AWS CLI updated via Homebrew"
  else
    log "Reinstalling AWS CLI to get latest version..."
    aws_install
  fi
}

aws_configure_interactive() {
  if ! command -v aws >/dev/null 2>&1; then
    die "AWS CLI not installed. Run 'pb aws:install' first."
  fi

  log "Starting AWS CLI configuration..."
  aws configure
  ok "AWS CLI configuration complete"
}

aws_configure_profile() {
  local profile_name="$1"
  if [ -z "$profile_name" ]; then
    die "Usage: aws_configure_profile <profile_name>"
  fi

  if ! command -v aws >/dev/null 2>&1; then
    die "AWS CLI not installed. Run 'pb aws:install' first."
  fi

  log "Configuring AWS CLI profile: $profile_name"
  aws configure --profile "$profile_name"
  ok "AWS CLI profile '$profile_name' configured"
}

aws_list_profiles() {
  if ! command -v aws >/dev/null 2>&1; then
    die "AWS CLI not installed. Run 'pb aws:install' first."
  fi

  local config_file="$HOME/.aws/config"
  local credentials_file="$HOME/.aws/credentials"

  log "AWS CLI Profiles:"

  if [ -f "$credentials_file" ]; then
    echo "From credentials file:"
    grep '^\[' "$credentials_file" | sed 's/\[//g; s/\]//g' | while read -r profile; do
      echo "  - $profile"
    done
  fi

  if [ -f "$config_file" ]; then
    echo "From config file:"
    grep '^\[profile ' "$config_file" | sed 's/\[profile //g; s/\]//g' | while read -r profile; do
      echo "  - $profile"
    done
  fi

  if [ ! -f "$credentials_file" ] && [ ! -f "$config_file" ]; then
    echo "  No profiles configured"
  fi
}

aws_status() {
  log "AWS CLI Status:"
  aws_detect

  if command -v aws >/dev/null 2>&1; then
    echo
    log "Current AWS Identity:"
    if aws sts get-caller-identity >/dev/null 2>&1; then
      aws sts get-caller-identity --output table
    else
      echo "  Not authenticated or no valid credentials"
    fi

    echo
    log "Default Region:"
    local region
    region=$(aws configure get region 2>/dev/null)
    if [ -n "$region" ]; then
      echo "  $region"
    else
      echo "  Not configured"
    fi

    echo
    aws_list_profiles
  fi
}

aws_set_region() {
  local region="$1"
  local profile="$2"

  if [ -z "$region" ]; then
    die "Usage: aws_set_region <region> [profile]"
  fi

  if ! command -v aws >/dev/null 2>&1; then
    die "AWS CLI not installed. Run 'pb aws:install' first."
  fi

  if [ -n "$profile" ]; then
    aws configure set region "$region" --profile "$profile"
    ok "Set region '$region' for profile '$profile'"
  else
    aws configure set region "$region"
    ok "Set default region to '$region'"
  fi
}

aws_login_sso() {
  local profile="$1"

  if ! command -v aws >/dev/null 2>&1; then
    die "AWS CLI not installed. Run 'pb aws:install' first."
  fi

  if [ -n "$profile" ]; then
    log "Logging in to AWS SSO with profile: $profile"
    aws sso login --profile "$profile"
  else
    log "Logging in to AWS SSO with default profile"
    aws sso login
  fi

  ok "AWS SSO login complete"
}
