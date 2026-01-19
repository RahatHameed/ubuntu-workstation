# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

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
