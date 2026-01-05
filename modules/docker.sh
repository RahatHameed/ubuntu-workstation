#!/bin/bash
# docker.sh - Docker Engine + Docker Desktop installation module

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

install_docker_engine() {
    if command_exists docker; then
        print_status "Docker Engine already installed"
        return 0
    fi

    print_info "Installing Docker Engine..."

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY-RUN] Would install Docker dependencies"
        print_info "[DRY-RUN] Would add Docker GPG key and repository"
        print_info "[DRY-RUN] Would install docker-ce, docker-ce-cli, containerd.io"
        print_info "[DRY-RUN] Would add user to docker group"
        return 0
    fi

    # Install dependencies
    sudo apt install -y ca-certificates curl gnupg lsb-release

    # Add Docker GPG key
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null || true

    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Update and install
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Add user to docker group
    sudo usermod -aG docker "$USER"

    print_status "Docker Engine installed"
    print_warning "Log out and back in for docker group to take effect"
}

install_docker_desktop() {
    if [[ -f /opt/docker-desktop/bin/docker-desktop ]]; then
        print_status "Docker Desktop already installed"
        return 0
    fi

    print_info "Installing Docker Desktop..."

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY-RUN] Would download Docker Desktop .deb"
        print_info "[DRY-RUN] Would install Docker Desktop"
        return 0
    fi

    local desktop_url="https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb"
    wget -q --show-progress -O /tmp/docker-desktop.deb "$desktop_url"
    sudo apt install -y /tmp/docker-desktop.deb
    rm /tmp/docker-desktop.deb

    print_status "Docker Desktop installed"
}

install_docker() {
    print_section "Docker Setup"

    install_docker_engine
    install_docker_desktop
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_docker
fi
