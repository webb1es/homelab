#!/usr/bin/env bash
# Run this ON your main dev Mac. Points your local `docker` CLI at the
# homelab Mac's OrbStack engine over SSH (via Tailscale), so
# `docker build` / `docker compose up` run there instead of locally.
set -euo pipefail

HOST="${1:?Usage: setup-docker-context.sh <user@tailscale-hostname> [context-name]}"
NAME="${2:-homelab}"

docker context create "$NAME" \
  --docker "host=ssh://${HOST}" \
  --description "OrbStack on homelab Mac, via Tailscale"

docker context use "$NAME"

echo "Docker CLI now points at ${HOST}. 'docker context use default' switches back to local."
docker info --format '{{.Name}}: {{.OperatingSystem}} / {{.OSType}}'
