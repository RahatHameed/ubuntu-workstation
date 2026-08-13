# Changelog

All notable changes to this project will be documented in this file.

## Unreleased

### Added

- `darkmode` module: switches the GNOME colour scheme to dark at sunset and
  back at sunrise, via a systemd user timer rather than a shell extension so it
  needs no logout. Sunrise and sunset are computed locally from coordinates that
  default to the system timezone's.
- `dark-at-sunset` also follows Claude Code's theme, which has no "follow the
  system" option of its own, by rewriting `theme` in `~/.claude/settings.json`
  at each switch. The configured variant is kept, so `dark-daltonized` becomes
  `light-daltonized`. Opt out with `--no-claude`.

- `./uninstall.sh -m darkmode` — stops and removes the timer, service and
  script, and is included in interactive and `--all` runs. The colour scheme and
  Claude Code's theme are left as they are.

### Fixed

- `darkmode` module now sets GNOME Terminal's `theme-variant` to `system`.
  Ubuntu ships it as `dark`, an app-level override that kept the terminal dark
  through the day regardless of the colour scheme.

## [Unreleased]

### Added
- `startup` module (`modules/startup.sh`) - installs the login autostart entry on
  its own via `./install.sh -m startup`, no longer requiring the full `desktop`
  module (Plank, Xorg session switch, GNOME tweaks)
- `./uninstall.sh -m startup` to remove the autostart entry

### Changed
- `desktop` module now delegates autostart setup to the `startup` module instead
  of writing the entry itself

## 2026-02-10

### Added
- `utils/pdf-sign.sh` - PDF signing helper using Xournal++
- `pdf-sign` shell alias

## 2026-01-21

### Added
- `teams-for-linux` to startup script (replaces broken Teams PWA)
- `vpn/ipv6-disable.sh` - Standalone IPv6 leak protection script with config support
- `ipv6_disable` config option in `config.yaml` (disabled by default for safety)
- `ipv6` shell alias for quick enable/disable/status commands
- Startup script now applies IPv6 config automatically on boot

### Changed
- IPv6 protection is now config-driven and applies to all VPN providers

## 2026-01-19

### Added
- IPv6 leak protection for NordVPN provider - automatically disables IPv6 on connect and re-enables on disconnect to prevent IP leaks

## 2026-01-14

### Added
- City support for VPN connections (`vpn-connect.sh connect Germany Frankfurt`)

### Changed
- Startup script now tolerates VPN connection failures without blocking other apps

## 2026-01-06

### Added
- VPN module with pluggable provider architecture
- Support for Mullvad, NordVPN, and ProtonVPN
- `vpn-connect.sh` wrapper script for unified VPN management
- Provider template for adding custom VPN providers

## 2026-01-05

### Added
- Reorganized scripts into `startup/`, `docker/`, and `vpn/` subdirectories
- `plank-start.sh` script for Wayland compatibility (forces X11 backend)
- Shell aliases documentation for convenience commands

### Fixed
- SCRIPT_DIR variable conflict in installers
- Added Xorg session requirement note for Plank dock

### Changed
- Updated README with new directory structure
