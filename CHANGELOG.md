# Changelog

All notable changes to this project will be documented in this file.

## Unreleased

### Added

- `docker/docker-cleanup.sh` removes orphaned containers: ones whose image ID
  no longer exists in the local store, so nothing can restart or rebuild them.
  A container still running on an image *tag* that has since been rebuilt is
  reported instead of removed - the usual state after building on a running
  stack - and `--all-orphans` opts into removing those as well.
- `docker/docker-cleanup.sh --all` removes every container, running or not.
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

### Changed

- Slack is installed as a Chrome web app instead of the snap — a second Electron
  runtime for a client that is already a web app. A Chrome-registered PWA is
  preferred when one is installed: it has an app id, so its launcher and
  `startup-office.sh` both return to the window that is already open. Where
  there is none the module writes a `--app` launcher (its own icon, dock entry
  and `StartupWMClass`) as a fallback, and clears it out once the real app
  appears — a `--app` window has no app identity, so every click on it opened
  another Slack window. `./uninstall.sh -m apps` removes the fallback launcher,
  and still removes the snap for anyone who has one.

### Fixed

- `docker/docker-cleanup.sh` now removes only stopped containers (`exited`,
  `created`, `dead`) instead of force-removing every container. It runs
  automatically from `startup-office.sh`, where `docker rm -f $(docker ps -aq)`
  killed containers that were deliberately left running.
- `dark-at-sunset` now swaps GNOME Terminal's profile colours, turning
  `use-theme-colors` off to do it. Following the system theme does not follow
  the colour scheme: Yaru hardcodes `terminal-window .terminal-screen` to the
  aubergine `#300A24` in its light stylesheet as well as its dark one, so the
  terminal screen stayed dark at noon while its titlebar and tabs correctly
  went light. Opt out with `--no-terminal`; the palette is left alone.
- `dark-at-sunset` now swaps `gtk-theme` as well, between the light and dark
  variant of whatever is configured (`Yaru` and `Yaru-dark`, the accent kept).
  GTK3 apps on Ubuntu ignore `color-scheme` — their
  `gtk-application-prefer-dark-theme` stays off however that key is set — so
  GNOME Terminal, and every other GTK3 window, previously kept the appearance it
  started with all day. Opt out with `--no-gtk-theme`.
- `darkmode` module now sets GNOME Terminal's `theme-variant` to `system`.
  Ubuntu ships it as `dark`, an app-level override that kept the terminal's
  window chrome dark through the day regardless of the colour scheme.
  `gnome-terminal-server` reads it once at startup, so the module now says when
  terminals need closing for the change to land. The screen inside the window is
  a separate matter, handled above.

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
