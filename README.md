# Pi Agent Config

Cross-platform auto-syncing configuration for Pi coding agent.

## Setup (new machine)

```bash
git clone git@github.com:rdandnayak/pi-agent.git ~/.pi
cd ~/.pi
make install
```

That's it. The sync runs every 15 minutes automatically.

### Optional: one-liner alias

Add to your `.zshrc` / `.bashrc`:

```bash
alias pi-setup='git clone git@github.com:rdandnayak/pi-agent.git ~/.pi && cd ~/.pi && make install'
```

## Commands

| Command | Description |
|---------|-------------|
| `make install` | Install auto-sync (detects OS automatically) |
| `make uninstall` | Remove auto-sync |
| `make status` | Check sync status and recent logs |

## What gets synced

- `agent/settings.json` — preferences and config
- `agent/models-store.json` — model configurations
- `agent/extensions/` — custom extensions
- `.gitignore`, `README.md`, `Makefile`, `sync.sh`

## What does NOT get synced

- `agent/auth.json` — API keys and tokens (sensitive)
- `agent/trust.json` — trust decisions
- `agent/sessions/` — conversation history
- `agent/bin/` — binaries
- `agent/npm/node_modules/` — reinstallable

## How it works

**macOS**: launchd agent (`~/Library/LaunchAgents/com.pi.sync.plist`)

**Linux** (Raspberry Pi, etc.): systemd user timer (`pi-sync.timer`)

**WSL**: systemd if enabled, otherwise cron fallback

The sync script (`sync.sh`) does:
1. `git pull --rebase` — fast-forward or replay local changes
2. `git add -A` — stage all changes (respects `.gitignore`)
3. Commit + push if there are changes
4. If conflict on pull: abort rebase, log error, skip this cycle

## Logs

```bash
tail -f ~/.pi/.sync.log
```
