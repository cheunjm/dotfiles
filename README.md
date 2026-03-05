# dotfiles

Managed with [chezmoi](https://chezmoi.io) + [1Password](https://1password.com).

## Contents

| File | Description |
|------|-------------|
| `dot_zshrc.tmpl` | zsh config (1Password secrets injected) |
| `dot_gitconfig` | Git config |
| `dot_zprofile` | Homebrew shellenv |
| `private_dot_ssh/config.tmpl` | SSH config (host/user from chezmoi data) |
| `dot_tmux.conf.local` | tmux config |
| `Brewfile` | Homebrew packages |

## Bootstrap (New Machine)

### Prerequisites

```bash
# 1. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install chezmoi + 1Password CLI
brew install chezmoi 1password-cli

# 3. Sign in to 1Password (service account)
export OP_SERVICE_ACCOUNT_TOKEN=<your-token>
```

### Setup

```bash
# Initialize dotfiles
chezmoi init https://github.com/cheunjm/dotfiles.git

# Configure local data (machine-specific)
cat >> ~/.config/chezmoi/chezmoi.toml << EOF

[data]
  mac_studio_ip = "<this-machine-ip>"
  ssh_user = "<your-username>"
EOF

# Apply
chezmoi apply
```

### Install Packages

```bash
cd ~/.local/share/chezmoi
brew bundle install
```

## Autopilot (Auto PR on Changes)

Changes to tracked dotfiles are automatically submitted as PRs.

```bash
# Enable
touch ~/.dotfiles-autopilot

# Disable
rm ~/.dotfiles-autopilot
```

PR notifications go to `#engineering-updates` on Slack.

## Adding New Files

```bash
chezmoi add ~/.your-config-file
cd ~/.local/share/chezmoi
git add -A && git commit -m "feat: add .your-config-file"
# autopilot will PR it, or push manually
```
