.PHONY: install uninstall status

SHELL := /bin/bash
USER := $(shell whoami)
HOME_DIR := $(shell echo ~)
SYNC_SCRIPT := $(HOME_DIR)/.pi/sync.sh

# Detect OS
UNAME_S := $(shell uname -s)

install: $(UNAME_S)

Darwin: install-launchd
Linux: install-linux

uninstall: $(UNAME_S)-uninstall

Darwin-uninstall: uninstall-launchd
Linux-uninstall: uninstall-linux

# ─── macOS (launchd) ────────────────────────────────────────────────

install-launchd:
	@echo ">>> Detected macOS — installing launchd agent"
	@chmod +x $(SYNC_SCRIPT)
	@sed "s|/Users/USERNAME|$(HOME_DIR)|g" $(HOME_DIR)/.pi/com.pi.sync.plist \
		> /tmp/com.pi.sync.plist
	@cp /tmp/com.pi.sync.plist $(HOME_DIR)/Library/LaunchAgents/com.pi.sync.plist
	@launchctl unload $(HOME_DIR)/Library/LaunchAgents/com.pi.sync.plist 2>/dev/null || true
	@launchctl load $(HOME_DIR)/Library/LaunchAgents/com.pi.sync.plist
	@echo ">>> Installed! Syncing every 15 minutes."
	@echo ">>> Logs: ~/.pi/.sync.log"

uninstall-launchd:
	@echo ">>> Removing launchd agent"
	@launchctl unload $(HOME_DIR)/Library/LaunchAgents/com.pi.sync.plist 2>/dev/null || true
	@rm -f $(HOME_DIR)/Library/LaunchAgents/com.pi.sync.plist
	@echo ">>> Uninstalled."

# ─── Linux (systemd, with cron fallback) ────────────────────────────

install-linux:
	@if command -v systemctl &>/dev/null && systemctl --user status &>/dev/null; then \
		$(MAKE) install-systemd; \
	else \
		$(MAKE) install-cron; \
	fi

install-systemd:
	@echo ">>> Detected Linux with systemd — installing user service + timer"
	@chmod +x $(SYNC_SCRIPT)
	@mkdir -p $(HOME_DIR)/.config/systemd/user
	@sed "s|~|$(HOME_DIR)|g" $(HOME_DIR)/.pi/pi-sync.service > $(HOME_DIR)/.config/systemd/user/pi-sync.service
	@sed "s|~|$(HOME_DIR)|g" $(HOME_DIR)/.pi/pi-sync.timer > $(HOME_DIR)/.config/systemd/user/pi-sync.timer
	@systemctl --user daemon-reload
	@systemctl --user enable pi-sync.timer
	@systemctl --user start pi-sync.timer
	@echo ">>> Installed! Syncing every 15 minutes."
	@echo ">>> Check status: systemctl --user status pi-sync.timer"

uninstall-systemd:
	@echo ">>> Removing systemd user service + timer"
	@systemctl --user stop pi-sync.timer 2>/dev/null || true
	@systemctl --user disable pi-sync.timer 2>/dev/null || true
	@systemctl --user stop pi-sync.service 2>/dev/null || true
	@rm -f $(HOME_DIR)/.config/systemd/user/pi-sync.service
	@rm -f $(HOME_DIR)/.config/systemd/user/pi-sync.timer
	@systemctl --user daemon-reload
	@echo ">>> Uninstalled."

install-cron:
	@echo ">>> Detected Linux without systemd — installing cron job"
	@chmod +x $(SYNC_SCRIPT)
	@(crontab -l 2>/dev/null | grep -v "pi/sync.sh"; echo "*/15 * * * * $(SYNC_SCRIPT)") | crontab -
	@echo ">>> Installed! Syncing every 15 minutes."
	@echo ">>> Check: crontab -l"

uninstall-cron:
	@echo ">>> Removing cron job"
	@(crontab -l 2>/dev/null | grep -v "pi/sync.sh") | crontab -
	@echo ">>> Uninstalled."

# ─── Status ─────────────────────────────────────────────────────────

status:
	@echo "=== Pi Sync Status ==="
	@echo "Platform: $(UNAME_S)"
	@echo ""
	@if [ "$(UNAME_S)" = "Darwin" ]; then \
		launchctl list | grep com.pi.sync || echo "Not running"; \
	elif command -v systemctl &>/dev/null && systemctl --user status pi-sync &>/dev/null; then \
		systemctl --user status pi-sync --no-pager; \
	else \
		crontab -l 2>/dev/null | grep "pi/sync.sh" || echo "No cron job found"; \
	fi
	@echo ""
	@echo "=== Recent log ==="
	@tail -5 $(HOME_DIR)/.pi/.sync.log 2>/dev/null || echo "No log yet"
