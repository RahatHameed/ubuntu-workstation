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
| `vpn` | Mullvad, NordVPN, or ProtonVPN |

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
./install.sh -m vpn        # Only VPN setup
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
│   ├── desktop.sh          # Desktop customization
│   └── vpn.sh              # VPN installation
├── startup/
│   ├── startup-office.sh   # Startup apps launcher
│   └── plank-start.sh      # Start Plank dock with X11 backend
├── docker/
│   └── docker-cleanup.sh   # Docker cleanup utility
├── vpn/
│   ├── vpn-connect.sh      # VPN connection wrapper
│   ├── ipv6-disable.sh     # IPv6 leak protection
│   └── providers/          # Pluggable VPN providers
│       ├── _template.sh    # Template for new providers
│       ├── mullvad.sh
│       ├── nordvpn.sh
│       └── protonvpn.sh
├── utils/
│   └── pdf-sign.sh         # PDF signing with Xournal++
├── troubleshooting/        # Issue tracking and solutions
│   └── teams-calendar-issue.md
└── README.md
```

## Troubleshooting Notes

The `troubleshooting/` directory contains documentation for known issues and their solutions:

| File | Issue |
|------|-------|
| `teams-calendar-issue.md` | Teams calendar "AccountSourceListStore" error |

View an issue:
```bash
cat ~/scripts/troubleshooting/teams-calendar-issue.md
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

## VPN Module

The VPN module (`./install.sh -m vpn`) supports multiple providers:

| Provider | Installation | Authentication |
|----------|--------------|----------------|
| Mullvad | Official repo + apt | Account number |
| NordVPN | Official install script | Browser login |
| ProtonVPN | Official repo + apt | CLI login |

### Configuration

Set your preferred provider in `config.yaml`:

```yaml
vpn:
  provider: mullvad          # mullvad, nordvpn, or protonvpn
  default_country: de        # Default connection country
  ipv6_disable: true         # Disable IPv6 to prevent leaks (recommended)
  account_number: ""         # Mullvad account (optional)
```

### VPN Connection Script

After installation, use `vpn/vpn-connect.sh` to manage connections:

```bash
./vpn/vpn-connect.sh connect              # Connect to default country
./vpn/vpn-connect.sh connect Germany      # Connect to Germany
./vpn/vpn-connect.sh connect Germany Frankfurt  # Connect to specific city
./vpn/vpn-connect.sh disconnect           # Disconnect
./vpn/vpn-connect.sh status               # Show status
./vpn/vpn-connect.sh is-connected         # Check connection (for scripts)
./vpn/vpn-connect.sh list-providers       # List available providers
```

### IPv6 Leak Protection

VPNs often don't route IPv6 traffic, causing your real IP to leak. The `ipv6-disable.sh` script prevents this:

```bash
ipv6 disable   # Force disable IPv6
ipv6 enable    # Force enable IPv6
ipv6 persist   # Make config persistent (survives reboot)
ipv6 status    # Check current status and external IPs
ipv6           # Apply config setting (default: disable)
```

**Configuration** (`config.yaml`):

```yaml
vpn:
  ipv6_disable: true    # true = disable IPv6 (recommended), false = enable
```

**Behavior:**
- **Startup:** Applied automatically by `startup-office.sh` based on config
- **Changes are temporary** unless you run `ipv6 persist`
- **Persist:** Creates `/etc/sysctl.d/99-disable-ipv6.conf` for settings to survive reboot
- **Default:** IPv6 disabled to prevent leaks

### Adding a New VPN Provider

The VPN module uses a pluggable provider architecture. To add a new provider:

1. Copy the template:
   ```bash
   cp vpn/providers/_template.sh vpn/providers/myvpn.sh
   ```

2. Implement the required functions in `myvpn.sh`:
   ```bash
   provider_install()        # Install the VPN client
   provider_configure()      # Post-install setup instructions
   provider_connect()        # Connect to VPN
   provider_disconnect()     # Disconnect from VPN
   provider_status()         # Print status
   provider_is_connected()   # Return 0 if connected
   ```

3. Use your new provider:
   ```bash
   # Via environment variable
   VPN_PROVIDER=myvpn ./vpn/vpn-connect.sh connect

   # Or edit vpn-connect.sh to change the default
   VPN_PROVIDER="${VPN_PROVIDER:-myvpn}"
   ```

See `vpn/providers/_template.sh` for a complete example with documentation.

## Utility Scripts

### startup/startup-office.sh

Launches work applications on login:
- PhpStorm, Slack, Teams, Chrome, Plank, Docker Desktop, Terminal

**Setup as startup application:**

```bash
# Create autostart entry
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/startup-office.desktop << EOF
[Desktop Entry]
Type=Application
Exec=$HOME/scripts/startup/startup-office.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Work Apps
EOF
```

### startup/plank-start.sh

Start Plank dock with X11 backend (fixes Wayland compatibility):

```bash
./startup/plank-start.sh
```

### docker/docker-cleanup.sh

Fixes "port already in use" errors after restart:

```bash
./docker/docker-cleanup.sh
```

### vpn/ipv6-disable.sh

Disables IPv6 to prevent VPN leaks:

```bash
./vpn/ipv6-disable.sh           # Apply config (disable if ipv6_disable: true)
./vpn/ipv6-disable.sh disable   # Force disable IPv6
./vpn/ipv6-disable.sh enable    # Force enable IPv6
./vpn/ipv6-disable.sh persist   # Make config persistent (survives reboot)
./vpn/ipv6-disable.sh status    # Check status and external IPs
```

### utils/pdf-sign.sh

Opens PDF in Xournal++ for signing and annotation:

```bash
./utils/pdf-sign.sh document.pdf    # Open specific PDF
./utils/pdf-sign.sh                 # Opens file picker (if zenity installed)
```

**Requires:** `sudo apt install xournalpp`

**Tips for signing:**
- Text tool (T): Add date/text
- Pen tool: Draw signature
- Image tool: Insert signature image
- File > Export as PDF to save signed version

## Shell Aliases

For convenience, add aliases to your `~/.zshrc` or `~/.bashrc`:

```bash
# Custom script aliases
alias plank-start='$HOME/scripts/startup/plank-start.sh'
alias docker-cleanup='$HOME/scripts/docker/docker-cleanup.sh'
alias vpn='$HOME/scripts/vpn/vpn-connect.sh'
alias ipv6='$HOME/scripts/vpn/ipv6-disable.sh'
alias pdf-sign='$HOME/scripts/utils/pdf-sign.sh'
```

After adding, reload your shell:

```bash
source ~/.zshrc  # or source ~/.bashrc
```

### Available Aliases

| Alias | Script | Description |
|-------|--------|-------------|
| `plank-start` | `startup/plank-start.sh` | Start Plank dock with X11 backend |
| `docker-cleanup` | `docker/docker-cleanup.sh` | Fix port conflicts from orphaned docker-proxy |
| `vpn` | `vpn/vpn-connect.sh` | VPN connection manager |
| `ipv6` | `vpn/ipv6-disable.sh` | IPv6 leak protection (disable/enable/status) |
| `pdf-sign` | `utils/pdf-sign.sh` | Open PDF in Xournal++ for signing |

## Requirements

- Ubuntu 22.04 or newer
- sudo access
- Internet connection

## Post-Installation

1. **Log out and select "Ubuntu on Xorg"** from the gear icon on login screen (required for Plank)
2. **Log back in** for shell and Docker group changes to take effect
3. **Configure Plank dock** - `Ctrl + right-click` on dock
4. **Apply theme** in GNOME Tweaks (if WhiteSur installed)
5. **Configure PhpStorm terminal** - Set shell path to `/usr/bin/zsh`

> **Important:** Plank dock does not work on Wayland. You must use Xorg session.

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

Edit `startup/startup-office.sh` to add/remove applications.

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
