#!/usr/bin/env bash
# Run this locally, on the homelab Mac itself.
# Configures it to stay up headless and reachable over Tailscale.
# Safe to re-run.
set -euo pipefail

echo "== Power settings: never sleep, wake on network, restart automatically =="
# GUI: System Settings > Battery > Options > "Prevent automatic sleeping
# on power adapter when the display is off"
sudo pmset -a sleep 0
# No GUI equivalent — disk-sleep timing isn't exposed in System Settings.
sudo pmset -a disksleep 0
# GUI: System Settings > Lock Screen > "Turn display off when inactive"
sudo pmset -a displaysleep 10
# GUI: System Settings > Battery > Options > "Wake for network access"
sudo pmset -a womp 1
# No GUI equivalent on a MacBook — "Start up after power failure" only
# appears in Energy Saver on desktop Macs.
sudo pmset -a autorestart 1
# No GUI equivalent on a MacBook, same reason as autorestart above.
sudo systemsetup -setrestartfreeze on >/dev/null

echo "== Remote Login (SSH) =="
# GUI: System Settings > General > Sharing > "Remote Login" toggle
sudo systemsetup -setremotelogin on >/dev/null

echo "== Tailscale SSH =="
# GUI: Tailscale menu bar icon > Preferences — may or may not expose this
# flag depending on your Tailscale version; the CLI is the reliable path.
if command -v tailscale >/dev/null 2>&1; then
  sudo tailscale up --ssh
else
  echo "tailscale CLI not found in PATH — open the Tailscale app and run 'tailscale up --ssh' manually." >&2
fi

echo
echo "Current power settings:"
pmset -g

cat <<'EOF'

MANUAL STEP (can't be scripted on recent macOS):
  System Settings > General > Sharing > turn ON "Screen Sharing".
  This gives you a screen-sharing fallback to SSH.

After this, from your dev Mac you should be able to:
  ssh <user>@<homelab-tailscale-hostname>
EOF
