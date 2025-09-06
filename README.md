# Portable Bootstrap (`pb`)

A comprehensive and modular toolkit for bootstrapping a consistent development environment across macOS and Linux. `pb` is designed to be idempotent, extensible, and production-ready with automated quality controls.

It automates the setup of shell profiles, essential development tools, cloud infrastructure tooling, and configurations with a single command, while keeping your home directory clean and organized.

## Features

- **One-Command Setup**: Run `./pb install` to get everything set up automatically
- **Comprehensive Tool Management**: Installs and manages Terraform, AWS CLI, Node.js, Git, and Homebrew
- **Idempotent & Safe**: Scripts can be run multiple times without causing issues
- **Modular & Extensible**: Core logic is broken into modules with clear separation of concerns
- **Centralized Profiles**: Customize aliases and PATH settings in the `profiles/` directory
- **Shell Integration**: Automatically wires itself into `.bashrc` and `.zshrc` with intelligent profile management
- **Cross-Platform Support**: Works seamlessly on macOS (Apple Silicon & Intel) and Linux (x86_64 & ARM64)
- **Infrastructure as Code**: Built-in Terraform commands for cloud infrastructure management
- **Cloud-Ready**: AWS CLI integration with profile management and SSO support
- **Quality Assurance**: Automated linting with ShellCheck and GitHub Actions CI/CD
- **Smart Updates**: Only updates profile files when changes are detected

## Project Structure

```
portable-bootstrap/
├── .github/
│   └── workflows/
│       └── lint.yml        # Automated CI/CD linting
├── modules/                # All command logic and features
│   ├── aws.sh             # AWS CLI management
│   ├── brew.sh            # Homebrew helpers
│   ├── core.sh            # Core utilities and logging
│   ├── git.sh             # Git tools and completions
│   ├── install.sh         # Installation and profile management
│   ├── node.sh            # Node.js and npm management
│   ├── status.sh          # Environment status reporting
│   └── terraform.sh       # Terraform installation and commands
├── profiles/              # User-customizable profiles
│   ├── aliases.sh         # Shell aliases and functions
│   └── path.sh            # PATH configuration
├── scripts/
│   └── lint.sh            # Local linting script
├── .shellcheckrc          # ShellCheck configuration
├── source.sh              # Main command dispatcher
└── README.md
```

## Installation

1.  **Clone the repository:**
    ```sh
    git clone https://github.com/your-username/portable-bootstrap.git
    cd portable-bootstrap
    ```

2.  **Run the installer:**
    ```sh
    ./source.sh install
    ```

This will:
- Install essential development tools (Terraform, AWS CLI) if not present
- Create a symbolic link to the `pb` script at `~/.local/bin/pb`
- Create the `~/.portable-bootstrap` directory to store generated profiles and completions
- Copy the contents of `profiles/` into `~/.portable-bootstrap/` (only when files are updated)
- Add the necessary `source` commands to your `~/.bashrc` or `~/.zshrc` file
- Set up shell aliases and PATH configurations

3.  **Restart your shell** or open a new terminal window to apply the changes.

## Usage

### Core Commands
- `pb install`: Installs the `pb` command and wires up your shell
- `pb status`: Displays comprehensive status of all tools and configurations
- `pb help`: Shows the help message with all available commands

### Git & Repository Management
- `pb new-repo <name>`: Creates a new Git repository and pushes it to GitHub (requires `gh` CLI)

### Homebrew Management (macOS)
- `pb brew:install-arm`: Installs Apple Silicon Homebrew
- `pb brew:install-intel`: Installs Intel (Rosetta) Homebrew  
- `pb brew:use-arm`: Switches the current shell session to use Apple Silicon Homebrew
- `pb brew:use-intel`: Switches the current shell session to use Intel Homebrew

### Terraform Commands
- `pb terraform:install`: Install Terraform via Homebrew or manual download
- `pb terraform:update`: Update Terraform to the latest version
- `pb terraform:init [directory]`: Initialize Terraform workspace
- `pb terraform:validate [directory]`: Validate Terraform configuration
- `pb terraform:plan [directory]`: Run terraform plan
- `pb terraform:apply [directory]`: Run terraform apply

### AWS CLI Commands
- `pb aws:install`: Install AWS CLI via Homebrew or manual download
- `pb aws:update`: Update AWS CLI to the latest version
- `pb aws:configure`: Interactive AWS configuration
- `pb aws:configure-profile <name>`: Configure named AWS profile
- `pb aws:list-profiles`: List all configured AWS profiles
- `pb aws:status`: Show comprehensive AWS configuration status
- `pb aws:set-region <region> [profile]`: Set AWS region for profile
- `pb aws:sso-login [profile]`: Perform AWS SSO login

### Node.js Management
- `pb node:install`: Install Node.js via nvm
- `pb node:update`: Update Node.js to the latest LTS version
- `pb node:status`: Show Node.js, npm, and nvm status

## Development & Quality Assurance

### Linting
The project includes comprehensive linting with ShellCheck:

```sh
# Run linting locally
./scripts/lint.sh

# Install ShellCheck if needed
brew install shellcheck
```

### Automated CI/CD
- GitHub Actions automatically run ShellCheck on all pull requests
- Linting configuration is stored in `.shellcheckrc`
- All shell scripts follow strict quality standards

## Customization

### Profile Customization
Edit files in the `profiles/` directory before running installation:

- **Aliases**: Add or modify shell aliases in `profiles/aliases.sh`
- **PATH**: Adjust the PATH configuration in `profiles/path.sh`

### Adding New Commands
1. Create a new shell script in the `modules/` directory
2. Define functions following the naming convention: `module_command()`
3. Add command dispatch logic to `source.sh`
4. Functions will be automatically available via the `pb` command

### Example Module Structure
```bash
#!/usr/bin/env bash
# modules/example.sh

example_hello() {
  log "Hello from example module!"
}

example_status() {
  if command -v example >/dev/null 2>&1; then
    ok "Example tool is installed"
  else
    warn "Example tool is not installed"
  fi
}
```

## Architecture

### Module System
- **Core utilities** (`core.sh`): Logging, downloading, path management
- **Tool modules**: Each major tool has its own module with install/update/status functions
- **Profile management** (`install.sh`): Handles shell integration and file copying
- **Command dispatch** (`source.sh`): Routes commands to appropriate module functions

### Design Principles
- **Idempotent operations**: All commands can be run multiple times safely
- **Cross-platform compatibility**: Supports macOS and Linux with architecture detection
- **Minimal dependencies**: Uses only standard Unix tools and package managers
- **Clean installation**: Keeps user home directory organized with centralized `.portable-bootstrap` directory