#!/bin/bash
# shell.sh - Zsh + Oh My Zsh installation module

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

install_shell() {
    print_section "Shell Setup (Zsh + Oh My Zsh)"

    # Install Zsh
    apt_install zsh

    # Install Oh My Zsh
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        print_info "Installing Oh My Zsh..."
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[DRY-RUN] Would install Oh My Zsh"
        else
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        fi
        print_status "Oh My Zsh installed"
    else
        print_status "Oh My Zsh already installed"
    fi

    # Set Zsh as default shell
    if [[ "$SHELL" != "$(which zsh)" ]]; then
        print_info "Setting Zsh as default shell..."
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[DRY-RUN] Would run: chsh -s $(which zsh)"
        else
            chsh -s "$(which zsh)"
        fi
        print_status "Zsh set as default shell (takes effect on next login)"
    else
        print_status "Zsh already default shell"
    fi

    print_warning "Log out and back in for Zsh to take effect"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_shell
fi
