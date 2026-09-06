#!/bin/bash
# Auto-sync ~/.pi to GitHub
# Handles: pull-rebase, commit, push with conflict detection

set -euo pipefail

REPO_DIR="$HOME/.pi"
LOG_FILE="$REPO_DIR/.sync.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

cd "$REPO_DIR" || { log "ERROR: Cannot cd to $REPO_DIR"; exit 1; }

# Pull with rebase to stay linear
if ! git pull --rebase origin main 2>> "$LOG_FILE"; then
    log "ERROR: Pull failed (merge conflict?). Aborting rebase."
    git rebase --abort 2>/dev/null
    exit 1
fi

# Stage all changes (respects .gitignore)
git add -A

# Commit and push if there are changes
if ! git diff --cached --quiet; then
    git commit -m "Auto-sync: $(date '+%Y-%m-%d %H:%M:%S')" 2>> "$LOG_FILE"
    if ! git push origin main 2>> "$LOG_FILE"; then
        log "ERROR: Push failed"
        exit 1
    fi
    log "Synced successfully"
else
    log "No changes to sync"
fi
