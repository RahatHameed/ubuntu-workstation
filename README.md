# Ubuntu Setup Scripts

Automated Ubuntu workstation setup with modular installation, dry-run support, and easy customization.

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/RahatHameed/ubuntu-workstation/main/install.sh | bash
```

Or clone and run:

```bash
git clone https://github.com/RahatHameed/ubuntu-workstation.git
cd ubuntu-workstation
./install.sh
```

## Features

- **Modular** - Install only what you need
- **Dry-run mode** - Preview changes before applying
- **Interactive mode** - Choose components during installation
- **Config file** - Customize via YAML config
- **Idempotent** - Safe to run multiple times

## What's Included

### Modules

| Module | Description |
|--------|-------------|
| `shell` | Zsh + Oh My Zsh |
| `git` | Git user, defaults, aliases |
| `ssh` | SSH key generation + agent auto-start |
| `apps` | Chrome, Slack, Teams, JetBrains Toolbox, etc. |
| `docker` | Docker Engine + Docker Desktop |
| `desktop` | Plank dock, GNOME tweaks, fonts |

### Available Applications

**Default (installed automatically):**

| App | Installation Method |
|-----|---------------------|
| Google Chrome | Official .deb |
| Slack | Snap |
| Microsoft Teams | Snap |
| JetBrains Toolbox | Official tarball |

**Optional (via config or interactive mode):**

| App | Installation Method |
|-----|---------------------|
| VS Code | Snap |
| Discord | Snap |
| Zoom | Official .deb |
| Postman | Snap |
| Spotify | Snap |
| DBeaver | Snap |

## Usage

### Full Installation (defaults)

```bash
./install.sh
```

### Interactive Mode

Choose what to install step by step:

```bash
./install.sh -i
```

### Install Specific Module

```bash
./install.sh -m shell      # Only Zsh + Oh My Zsh
./install.sh -m git        # Only Git configuration
./install.sh -m ssh        # Only SSH setup
./install.sh -m apps       # Only applications
./install.sh -m docker     # Only Docker
./install.sh -m desktop    # Only desktop customization
```

### Dry-Run Mode

Preview what would be installed:

```bash
./install.sh --dry-run
./install.sh -m apps --dry-run
```

### Custom Config

```bash
cp config.example.yaml config.yaml
# Edit config.yaml to customize
./install.sh -c config.yaml
```

### Include Claude CLI

```bash
./install.sh --claude
```

## Configuration

Copy `config.example.yaml` to `config.yaml` and customize:

```yaml
# Modules to install
modules:
  shell: true
  apps: true
  docker: true
  desktop: true

# Apps to install
apps:
  - chrome
  - slack
  - teams
  - jetbrains-toolbox
  # - vscode
  # - spotify

# Desktop settings
install_theme: false
font_scale: 1.25
```

## Uninstall

Remove installed components:

```bash
./uninstall.sh              # Interactive mode
./uninstall.sh -m apps      # Uninstall specific module
./uninstall.sh --all        # Uninstall everything
./uninstall.sh --dry-run    # Preview changes
```

**Safe by default:**
- SSH keys are kept (remove manually if needed)
- Git user.name/email kept
- Base packages kept (zsh, plank, etc.)

## Directory Structure

```
ubuntu-setup-scripts/
├── install.sh              # Main installer
├── uninstall.sh            # Uninstaller
├── config.example.yaml     # Example configuration
├── LICENSE                 # MIT License
├── modules/
│   ├── common.sh           # Shared functions
│   ├── shell.sh            # Zsh + Oh My Zsh
│   ├── git.sh              # Git configuration
│   ├── ssh.sh              # SSH key + agent setup
│   ├── apps.sh             # Work applications
│   ├── docker.sh           # Docker setup
│   └── desktop.sh          # Desktop customization
├── startup-office.sh       # Startup apps launcher
├── docker-cleanup.sh       # Docker cleanup utility
└── README.md
```

## Git Module

The Git module (`./install.sh -m git`) configures:

- **User setup** - Prompts for name/email if not set
- **Default branch** - Sets to `main`
- **Editor** - Auto-detects VS Code or vim
- **Useful aliases:**
  - `git st` → status
  - `git co` → checkout
  - `git br` → branch
  - `git ci` → commit
  - `git lg` → pretty log
  - `git df` → diff
  - `git dfs` → diff staged

## SSH Module

The SSH module (`./install.sh -m ssh`) provides:

- **Generates SSH key** (ed25519) if not exists
- **Configures ssh-agent** to auto-start with shell
- **Auto-adds keys** to agent on login
- **Sets up ~/.ssh/config** for GitHub and GitLab
- **Displays public key** for easy copying

After running, add your public key to:
- GitHub: https://github.com/settings/ssh/new
- GitLab: https://gitlab.com/-/profile/keys

## Utility Scripts

### startup-office.sh

Launches work applications on login:
- PhpStorm, Slack, Chrome, Plank, Docker Desktop, Terminal

**Setup as startup application:**

```bash
# Create autostart entry
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/startup-office.desktop << EOF
[Desktop Entry]
Type=Application
Exec=$HOME/ubuntu-workstation/startup-office.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Work Apps
EOF
```

### docker-cleanup.sh

Fixes "port already in use" errors after restart:

```bash
./docker-cleanup.sh
```

## Requirements

- Ubuntu 22.04 or newer
- sudo access
- Internet connection

## Post-Installation

1. **Log out and back in** for shell and Docker group changes
2. **Configure Plank dock** - `Ctrl + right-click` on dock
3. **Apply theme** in GNOME Tweaks (if WhiteSur installed)
4. **Configure PhpStorm terminal** - Set shell path to `/usr/bin/zsh`

## Customization

### Add your own apps

Edit `modules/apps.sh` and add a function:

```bash
install_myapp() {
    snap_install "myapp"
    # or
    deb_install "myapp" "https://example.com/myapp.deb" "myapp"
}
```

Then add to the `install_apps()` function.

### Modify startup apps

Edit `startup-office.sh` to add/remove applications.

## License

MIT License - feel free to use and modify.

## Contributing

Contributions are welcome! Here's how you can help:

### Ideas for Contributions

| Area | Examples |
|------|----------|
| **New modules** | Node.js/NVM, Python/pyenv, Ruby/rbenv, Go, Rust |
| **New apps** | Add more applications to `modules/apps.sh` |
| **Distro support** | Linux Mint, Pop!_OS, elementary OS |
| **Themes** | Additional desktop themes and icon packs |
| **Shell configs** | Fish shell, custom Zsh themes |
| **Dev tools** | Database clients, API tools, cloud CLIs |
| **Documentation** | Improve docs, add screenshots, translations |
| **Bug fixes** | Fix issues, improve error handling |

### How to Contribute

1. **Fork** the repository
2. **Clone** your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/ubuntu-workstation.git
   ```
3. **Create** a feature branch:
   ```bash
   git checkout -b feature/add-nodejs-module
   ```
4. **Make** your changes following the existing code style
5. **Test** your changes:
   ```bash
   ./install.sh -m your-module --dry-run
   ```
6. **Commit** with a descriptive message:
   ```bash
   git commit -m "Add Node.js/NVM module"
   ```
7. **Push** and create a **Pull Request**

### Adding a New Module

1. Create `modules/your-module.sh`:
   ```bash
   #!/bin/bash
   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
   source "$SCRIPT_DIR/common.sh"

   install_your_module() {
       print_section "Your Module"
       # Your installation logic
   }

   if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
       install_your_module
   fi
   ```

2. Add to `install.sh` (interactive, run_module, run_all functions)
3. Add to `uninstall.sh`
4. Update `config.example.yaml`
5. Update `README.md`

### Guidelines

- Keep scripts **idempotent** (safe to run multiple times)
- Support **--dry-run** mode
- Use functions from `modules/common.sh`
- Add **error handling** for edge cases
- Test on a **fresh Ubuntu install** if possible
