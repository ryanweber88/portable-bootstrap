#!/usr/bin/env bash
# Terraform installation and management

terraform_detect() {
  if command -v terraform >/dev/null 2>&1; then
    terraform version | head -n1
  else
    echo "terraform not found"
  fi
}

terraform_install() {
  log "Installing Terraform..."

  if is_macos; then
    terraform_install_macos
  elif is_linux; then
    terraform_install_linux
  else
    die "Unsupported platform for Terraform installation"
  fi
}

terraform_install_macos() {
  if command -v brew >/dev/null 2>&1; then
    log "Installing Terraform via Homebrew..."
    brew tap hashicorp/tap
    brew install hashicorp/tap/terraform
    ok "Terraform installed via Homebrew"
  else
    log "Homebrew not found, installing Terraform manually..."
    terraform_install_manual_macos
  fi
}

terraform_install_manual_macos() {
  local arch_suffix
  case "$(arch_name)" in
    arm64) arch_suffix="darwin_arm64" ;;
    x86_64) arch_suffix="darwin_amd64" ;;
    *) die "Unsupported architecture: $(arch_name)" ;;
  esac

  local version="1.6.6"  # Latest stable as of creation
  local url="https://releases.hashicorp.com/terraform/${version}/terraform_${version}_${arch_suffix}.zip"
  local temp_dir="/tmp/terraform-install"

  ensure_dir "$temp_dir"
  ensure_dir "$PB_BIN_DIR"

  log "Downloading Terraform ${version} for ${arch_suffix}..."
  download "$url" "$temp_dir/terraform.zip"

  log "Extracting Terraform..."
  cd "$temp_dir" || die "Failed to change to temp directory"
  unzip -q terraform.zip
  chmod +x terraform
  mv terraform "$PB_BIN_DIR/"

  rm -rf "$temp_dir"
  ok "Terraform ${version} installed to $PB_BIN_DIR/terraform"
}

terraform_install_linux() {
  local arch_suffix
  case "$(arch_name)" in
    x86_64) arch_suffix="linux_amd64" ;;
    aarch64|arm64) arch_suffix="linux_arm64" ;;
    *) die "Unsupported architecture: $(arch_name)" ;;
  esac

  local version="1.6.6"  # Latest stable as of creation
  local url="https://releases.hashicorp.com/terraform/${version}/terraform_${version}_${arch_suffix}.zip"
  local temp_dir="/tmp/terraform-install"

  ensure_dir "$temp_dir"
  ensure_dir "$PB_BIN_DIR"

  log "Downloading Terraform ${version} for ${arch_suffix}..."
  download "$url" "$temp_dir/terraform.zip"

  log "Extracting Terraform..."
  cd "$temp_dir" || die "Failed to change to temp directory"
  unzip -q terraform.zip
  chmod +x terraform
  mv terraform "$PB_BIN_DIR/"

  rm -rf "$temp_dir"
  ok "Terraform ${version} installed to $PB_BIN_DIR/terraform"
}

terraform_update() {
  log "Updating Terraform..."

  if is_macos && command -v brew >/dev/null 2>&1; then
    brew upgrade hashicorp/tap/terraform
    ok "Terraform updated via Homebrew"
  else
    log "Reinstalling Terraform to get latest version..."
    terraform_install
  fi
}

terraform_init_workspace() {
  local workspace_dir="$1"
  if [ -z "$workspace_dir" ]; then
    workspace_dir="$(pwd)"
  fi

  if [ ! -f "$workspace_dir/main.tf" ] && [ ! -f "$workspace_dir/terraform.tf" ]; then
    die "No Terraform configuration files found in $workspace_dir"
  fi

  log "Initializing Terraform workspace in $workspace_dir..."
  cd "$workspace_dir" || die "Failed to change to workspace directory"
  terraform init
  ok "Terraform workspace initialized"
}

terraform_validate_config() {
  local workspace_dir="$1"
  if [ -z "$workspace_dir" ]; then
    workspace_dir="$(pwd)"
  fi

  log "Validating Terraform configuration in $workspace_dir..."
  cd "$workspace_dir" || die "Failed to change to workspace directory"
  terraform validate
  ok "Terraform configuration is valid"
}

terraform_plan() {
  local workspace_dir="$1"
  if [ -z "$workspace_dir" ]; then
    workspace_dir="$(pwd)"
  fi

  log "Running Terraform plan in $workspace_dir..."
  cd "$workspace_dir" || die "Failed to change to workspace directory"
  terraform plan
}

terraform_apply() {
  local workspace_dir="$1"
  if [ -z "$workspace_dir" ]; then
    workspace_dir="$(pwd)"
  fi

  log "Running Terraform apply in $workspace_dir..."
  cd "$workspace_dir" || die "Failed to change to workspace directory"
  terraform apply
}
