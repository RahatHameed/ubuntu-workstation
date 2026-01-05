#!/bin/bash
# ssh.sh - SSH key and agent setup module

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

SSH_KEY_TYPE="ed25519"
SSH_KEY_PATH="$HOME/.ssh/id_$SSH_KEY_TYPE"

generate_ssh_key() {
    if [[ -f "$SSH_KEY_PATH" ]]; then
        print_status "SSH key already exists: $SSH_KEY_PATH"
        return 0
    fi

    print_info "Generating SSH key ($SSH_KEY_TYPE)..."

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY-RUN] Would generate SSH key at $SSH_KEY_PATH"
        return 0
    fi

    # Create .ssh directory if it doesn't exist
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    # Get email for key comment
    local email
    email=$(git config --global user.email 2>/dev/null || echo "")

    if [[ -z "$email" ]]; then
        read -p "Enter your email for SSH key: " email
    fi

    # Generate key
    ssh-keygen -t "$SSH_KEY_TYPE" -C "$email" -f "$SSH_KEY_PATH" -N ""

    print_status "SSH key generated: $SSH_KEY_PATH"
}

configure_ssh_agent() {
    print_info "Configuring SSH agent..."

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY-RUN] Would configure SSH agent in shell config"
        return 0
    fi

    # Determine shell config file
    local shell_config
    if [[ -f "$HOME/.zshrc" ]]; then
        shell_config="$HOME/.zshrc"
    else
        shell_config="$HOME/.bashrc"
    fi

    # Check if already configured
    if grep -q "ssh-agent" "$shell_config" 2>/dev/null; then
        print_status "SSH agent already configured in $shell_config"
        return 0
    fi

    # Add SSH agent configuration
    cat >> "$shell_config" << 'EOF'

# SSH Agent - Auto-start and add keys
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" > /dev/null
fi

# Add SSH key to agent (if not already added)
ssh-add -l &>/dev/null || ssh-add ~/.ssh/id_ed25519 2>/dev/null
EOF

    print_status "SSH agent configured in $shell_config"
}

configure_ssh_config() {
    local ssh_config="$HOME/.ssh/config"

    if [[ -f "$ssh_config" ]] && grep -q "AddKeysToAgent" "$ssh_config"; then
        print_status "SSH config already set up"
        return 0
    fi

    print_info "Configuring SSH client..."

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY-RUN] Would configure ~/.ssh/config"
        return 0
    fi

    # Create or append to SSH config
    cat >> "$ssh_config" << 'EOF'

# Global SSH settings
Host *
    AddKeysToAgent yes
    IdentitiesOnly yes

# GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519

# GitLab
Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_ed25519
EOF

    chmod 600 "$ssh_config"
    print_status "SSH config updated: $ssh_config"
}

show_public_key() {
    local pub_key="$SSH_KEY_PATH.pub"

    if [[ ! -f "$pub_key" ]]; then
        print_warning "No public key found at $pub_key"
        return 1
    fi

    print_section "Your SSH Public Key"
    echo ""
    cat "$pub_key"
    echo ""
    print_info "Add this key to:"
    echo "  GitHub:  https://github.com/settings/ssh/new"
    echo "  GitLab:  https://gitlab.com/-/profile/keys"
    echo ""

    # Copy to clipboard if xclip is available
    if command_exists xclip; then
        cat "$pub_key" | xclip -selection clipboard
        print_status "Public key copied to clipboard!"
    elif command_exists xsel; then
        cat "$pub_key" | xsel --clipboard
        print_status "Public key copied to clipboard!"
    else
        print_info "Install xclip to auto-copy: sudo apt install xclip"
    fi
}

install_ssh() {
    print_section "SSH Setup"

    # Install openssh-client if not present
    apt_install openssh-client

    # Generate SSH key
    generate_ssh_key

    # Configure SSH agent to auto-start
    configure_ssh_agent

    # Configure SSH client
    configure_ssh_config

    # Show public key
    if [[ "$DRY_RUN" != true ]]; then
        show_public_key
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_ssh
fi
