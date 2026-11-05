# From the Coldstart-owned setup to lechdigital-infra

Coldstart was the first project on the server, so the server, the Caddy and the shared network were named after it, and
the Caddyfile lived in Coldstart's repository. By 2026-11-04 the live Caddyfile had three sites (CoreChoice, Coo, Cult
of Comfort) that were never committed there: a Coldstart redeploy would have taken their HTTPS down. This repository
takes over the edge; each step keeps every site up.

## Done

- 2026-11-04: the server renamed `ubuntu-4gb-nbg1-1` → `lechdigital-prod` (Hetzner and hostname); SSH alias
  `lechdigital-prod` (the old `coldstart-prod` still works).
- 2026-11-04: every project's repository in the Lech-Digital organisation; all public.
- 2026-11-04: the `deploy` user; the edge cut over (`lechdigital-caddy`, the certificates kept); every public container
  on `lechdigital_edge`; the edge off `coldstart_default`, which is now only Coldstart's own private network.
- 2026-11-04: Coldstart's compose without its Caddy (lead-engine #1).
- 2026-11-04: Coo, PurePrep, CoreChoice and Cult of Comfort deploy from GitHub on every push to `main`
  (`deploy-app.yml`); Coldstart is not in use and has no deploy workflow.

## Left

- `docker rm coldstart-caddy-1` on the server: the old Caddy, stopped and kept for a rollback.
- The weekly build-cache clean-up is still the copy lead-engine installed; `host/docker-cache-gc.*` here is the same.

## Later

- Uptime checks on every health URL (an external service, or Uptime Kuma on a second machine; not on this host).
- Backups off the host: restic to a Hetzner Storage Box, for each project's dumps in `/opt/<project>/backups`.
- The server's size: it uses about 1.4 GB of 4 GB with builds moved off it; resize when a new project needs it.
