# Portable Bootstrap (`pb`)

A lightweight and modular toolkit for bootstrapping a consistent development environment on macOS and Linux. `pb` is designed to be idempotent, extensible, and easy to maintain.

It automates the setup of shell profiles, essential tools, and configurations with a single command, while keeping your home directory clean.

## Features

- **One-Command Setup**: Run `./pb install` to get everything set up.
- **Idempotent & Safe**: Scripts can be run multiple times without causing issues.
- **Modular & Extensible**: Core logic is broken into modules. Add new commands by simply adding a new file to the `modules/` directory.
- **Centralized Profiles**: Customize aliases and PATH settings in the `profiles/` directory, which are then copied into place during installation.
- **Shell Integration**: Automatically wires itself into `.bashrc` and `.zshrc` to provide custom aliases and PATH adjustments.
- **Git Completions**: Installs and configures Git command-line completions for both Bash and Zsh.
- **Homebrew Helpers**: Includes commands for managing dual Apple Silicon and Intel Homebrew installations on macOS.

## Project Structure

```
portable-bootstrap/
├── modules/        # All command logic and features live here
│   ├── brew.sh
│   ├── core.sh
│   ├── git.sh
│   ├── install.sh
│   └── status.sh
├── profiles/       # User-customizable profiles
│   ├── aliases.sh
│   └── path.sh
├── pb              # The main executable script (dispatcher)
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
    ./pb install
    ```

This will:
- Create a symbolic link to the `pb` script at `~/.local/bin/pb`.
- Create the `~/.portable-bootstrap` directory to store generated profiles and completions.
- Copy the contents of `profiles/` into `~/.portable-bootstrap/`.
- Add the necessary `source` commands to your `~/.bashrc` or `~/.zshrc` file.

3.  **Restart your shell** or open a new terminal window to apply the changes.

## Usage

Here are the available commands:

- `pb install`: Installs the `pb` command and wires up your shell.
- `pb status`: Displays the current status of the environment and configuration.
- `pb new-repo <name>`: Creates a new Git repository and pushes it to GitHub (requires `gh` CLI).
- `pb brew:install-arm`: Installs Apple Silicon Homebrew.
- `pb brew:install-intel`: Installs Intel (Rosetta) Homebrew.
- `pb brew:use-arm`: Switches the current shell session to use Apple Silicon Homebrew.
- `pb brew:use-intel`: Switches the current shell session to use Intel Homebrew.
- `pb uninstall`: Removes the `pb` command and the `~/.portable-bootstrap` directory.
- `pb help`: Shows the help message.

## Customization

To customize the bootstrap process, you can edit the files in the `profiles/` directory before running the installation.

- **Aliases**: Add or modify shell aliases in `profiles/aliases.sh`.
- **PATH**: Adjust the PATH configuration in `profiles/path.sh`.
- **New Commands**: Add a new shell script to the `modules/` directory. The functions within it will be automatically available to the `pb` command dispatcher.