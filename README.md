# Webbies Homelab

Turns a Mac into an always-on, headless server reachable only over
Tailscale, that the main dev Mac can offload container work to via OrbStack.

## Layout

- `setup/homelab-mac-setup.sh` — **[run on: homelab Mac]** disables sleep,
  enables SSH, turns on Tailscale SSH.
- `remote/setup-docker-context.sh` — **[run on: dev Mac]** points the
  local `docker` CLI at the homelab Mac's OrbStack engine over SSH.
- `docker/` — **[runs on: homelab Mac]** Caddy (reverse proxy) in front of
  `code-server` (browser-based VS Code), reachable over the tailnet only.

## Setup

Three surfaces are involved: the **homelab Mac** (the server), your
**dev Mac** (where you work from), and the **Tailscale admin console**
(tailscale.com, for one DNS setting). Each step below says which one.

1. **[Homelab Mac]** Clone/copy this repo there, then run:

   ```bash
   ./setup/homelab-mac-setup.sh
   ```

   Follow the manual step it prints (enabling Screen Sharing via System
   Settings — recent macOS won't let this be toggled from the CLI).

2. **[Tailscale admin console]** Confirm MagicDNS is enabled (DNS tab) —
   this is what lets you use a plain hostname like `homelab-mac` instead
   of a `100.x.x.x` IP in every command below. It's usually on by default;
   if you'd rather use the IP, skip this and substitute it throughout.

3. **[Dev Mac]** Confirm you can reach the homelab Mac headless:

   ```bash
   ssh <user>@<homelab-tailscale-hostname>
   ```

4. **[Homelab Mac]** Set up the compose stack (either at the machine, or
   over the SSH session from step 3):

   ```bash
   cd docker
   cp .env.example .env   # edit CODE_SERVER_PASSWORD
   docker compose up -d
   ```

   `code-server` is now reachable at `http://<homelab-tailscale-hostname>/`
   from any device on your tailnet (Caddy proxies it on port 80) — try it
   from the dev Mac's browser.

5. **[Dev Mac]** Point your local `docker` CLI at the homelab Mac's
   OrbStack engine, so `docker build` / `docker compose up` run there
   instead of locally:

   ```bash
   ./remote/setup-docker-context.sh <user>@<homelab-tailscale-hostname>
   ```

   `docker context use default` switches back to local Docker at any time.

## Running with the lid closed

The `pmset` settings in the setup script stop idle sleep (lid open, sitting
unattended), but a closed lid is a separate mechanism — on Apple Silicon
it's enforced in firmware and `pmset` can't override it. Closing the lid
only stays awake ("clamshell mode") if, at that moment, the Mac is:

- connected to AC power, **and**
- connected to an external display (or a keyboard + mouse).

Keep both true and you can close the lid indefinitely — it just turns off
the internal panel, everything else (SSH, Tailscale, Docker) keeps running.
Drop either condition while the lid is closed and it will sleep, with no
software workaround.

## Adding services later

Add a service to `docker/docker-compose.yml`, join it to the `homelab`
network, and add a route for it in `docker/caddy/Caddyfile` (see the
commented example there). Candidates worth adding as needs grow: Ollama
for local LLM inference, a self-hosted CI runner, Syncthing for file sync
between the two Macs.
