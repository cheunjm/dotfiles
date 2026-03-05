#!/bin/bash
# dotfiles bootstrap script
# Usage: curl -fsSL https://raw.githubusercontent.com/cheunjm/dotfiles/main/bootstrap.sh | bash

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[bootstrap]${NC} $*"; }
warn() { echo -e "${YELLOW}[bootstrap]${NC} $*"; }

# 1. Homebrew
if ! command -v brew &>/dev/null; then
    log "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    log "Homebrew already installed."
fi

# 2. chezmoi
if ! command -v chezmoi &>/dev/null; then
    log "Installing chezmoi..."
    brew install chezmoi
else
    log "chezmoi already installed."
fi

# 3. 1Password CLI
if ! command -v op &>/dev/null; then
    log "Installing 1Password CLI..."
    brew install 1password-cli
else
    log "1Password CLI already installed."
fi

# 4. OP_SERVICE_ACCOUNT_TOKEN check
if [ -z "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]; then
    warn "OP_SERVICE_ACCOUNT_TOKEN not set."
    echo "  Set it with: export OP_SERVICE_ACCOUNT_TOKEN=<token>"
    echo "  Then re-run this script."
    exit 1
fi

# 5. chezmoi init
log "Initializing dotfiles..."
chezmoi init https://github.com/cheunjm/dotfiles.git

# 6. Machine-specific data
CHEZMOI_TOML="$HOME/.config/chezmoi/chezmoi.toml"
if ! grep -q "\[data\]" "$CHEZMOI_TOML" 2>/dev/null; then
    warn "Machine-specific data not set. Please add to $CHEZMOI_TOML:"
    echo ""
    echo "  [data]"
    echo "    mac_studio_ip = \"<this-machine-ip>\""
    echo "    ssh_user = \"<your-username>\""
    echo ""
    read -p "Enter IP (or press Enter to skip): " IP
    read -p "Enter SSH username (or press Enter to skip): " SSHUSER
    if [ -n "$IP" ] && [ -n "$SSHUSER" ]; then
        cat >> "$CHEZMOI_TOML" << EOF

[data]
  mac_studio_ip = "$IP"
  ssh_user = "$SSHUSER"
EOF
        log "Data written to chezmoi.toml."
    fi
fi

# 7. Apply
log "Applying dotfiles..."
chezmoi apply

# 8. Homebrew packages
log "Installing Homebrew packages..."
cd "$(chezmoi source-path)"
brew bundle install --no-lock

log "✅ Bootstrap complete!"
