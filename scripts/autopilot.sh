#!/bin/bash
# dotfiles autopilot — auto PR on changes
# Toggle: touch ~/.dotfiles-autopilot to enable, rm to disable

set -euo pipefail

CHEZMOI_DIR="$HOME/.local/share/chezmoi"
LOG="$HOME/.config/arami/autopilot.log"
SLACK_TOKEN_FILE="$HOME/.config/arami/slack-token"
SLACK_DM_CHANNEL="D0AGCKPS562"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG"; }

slack_notify() {
    local msg="$1"
    if [ -f "$SLACK_TOKEN_FILE" ]; then
        local token
        token=$(cat "$SLACK_TOKEN_FILE")
        curl -s -X POST https://slack.com/api/chat.postMessage \
            -H "Authorization: Bearer $token" \
            -H "Content-Type: application/json" \
            -d "{\"channel\":\"$SLACK_DM_CHANNEL\",\"text\":\"$msg\"}" \
            > /dev/null
    fi
}

# Toggle check
if [ ! -f "$HOME/.dotfiles-autopilot" ]; then
    log "Autopilot disabled (no ~/.dotfiles-autopilot). Skipping."
    exit 0
fi

# Check for changes
CHANGES=$(chezmoi status 2>/dev/null || true)
if [ -z "$CHANGES" ]; then
    log "No changes detected."
    exit 0
fi

log "Changes detected:"
echo "$CHANGES" >> "$LOG"

# Get GitHub App installation token
TOKEN=$(python3 "$CHEZMOI_DIR/.scripts/get-github-token.py" 2>>"$LOG")
if [ -z "$TOKEN" ]; then
    log "ERROR: Failed to get GitHub token."
    exit 1
fi

BRANCH="auto/dotfiles-$(date '+%Y%m%d-%H%M%S')"
cd "$CHEZMOI_DIR"

# Set remote URL with token
git remote set-url origin "https://x-access-token:${TOKEN}@github.com/cheunjm/dotfiles.git"

# Fetch latest main and create branch
git fetch origin main --quiet
git checkout -b "$BRANCH" origin/main --quiet

# Re-add changed files
chezmoi re-add 2>>"$LOG" || true

# Stage and commit
git add -A
if git diff --cached --quiet; then
    log "Nothing to commit after re-add."
    git checkout - --quiet
    git branch -D "$BRANCH" --quiet
    exit 0
fi

CHANGED_FILES=$(git diff --cached --name-only | tr '\n' ' ')

git \
    -c user.name="arami-openclaw[bot]" \
    -c user.email="3012876+arami-openclaw[bot]@users.noreply.github.com" \
    commit -m "chore: sync dotfiles $(date '+%Y-%m-%d %H:%M')" --quiet

# Push
git push origin "$BRANCH" --quiet

# Create PR
PR_URL=$(GH_TOKEN="$TOKEN" gh pr create \
    --repo cheunjm/dotfiles \
    --base main \
    --head "$BRANCH" \
    --title "chore: sync dotfiles $(date '+%Y-%m-%d')" \
    --body "Automated dotfiles sync via autopilot.

Changes detected by \`chezmoi status\`:
\`\`\`
$CHANGES
\`\`\`
" 2>>"$LOG")

log "PR created: $PR_URL"

# Slack notification
slack_notify "🤖 dotfiles PR 생성됨\n• 변경: $CHANGED_FILES\n→ $PR_URL"

# Back to previous branch
git checkout - --quiet 2>/dev/null || true
