# From the Coldstart-owned setup to lechdigital-infra

Coldstart was the first project on the server, so the server, the Caddy and the shared network were named after it, and
the Caddyfile lived in Coldstart's repository. By 2026-11-04 the live Caddyfile had three sites (CoreChoice, Coo, Cult
of Comfort) that were never committed there: a Coldstart redeploy would have taken their HTTPS down. This repository
takes over the edge; each step keeps every site up.

## Done

- 2026-11-04: the server renamed `ubuntu-4gb-nbg1-1` → `lechdigital-prod` (Hetzner and hostname); SSH alias
  `lechdigital-prod` (the old `coldstart-prod` still works).
- 2026-11-04: PurePrep and CoreChoice moved to the Lech-Digital organisation (Coo and Cult of Comfort were there).

## To do, in order

1. **lead-engine (Coldstart) to Lech-Digital**: the transfer stalled on GitHub's side; retry in Settings → Transfer.
2. **The deploy user**: `ssh-keygen -t ed25519 -N '' -C lechdigital-deploy -f ~/.ssh/lechdigital_deploy_ed25519`, then
   `./host/setup-deploy-user.sh ~/.ssh/lechdigital_deploy_ed25519.pub coo pureprep corechoice cultofcomfort coldstart`.
3. **The edge**: `./edge/cutover.sh --confirm` (a few seconds of HTTPS down; it compares every site before and after;
   `--rollback` undoes it). From then on Caddy's config is this repository's.
4. **Coldstart**: remove the `caddy` service and the Caddyfile from lead-engine's `docker-compose.prod.yml` (otherwise a
   Coldstart deploy fights the edge for ports 80 and 443), then `docker rm coldstart-caddy-1` on the server.
5. **Each project onto `lechdigital_edge` and the deploy workflow**, one at a time: Coo, PurePrep, CoreChoice, Cult of
   Comfort, Coldstart. In its compose file, the public container's network `coldstart_default` → `lechdigital_edge`
   (external), the image tagged `${IMAGE_TAG:-latest}`; add `.github/workflows/deploy.yml` and the two secrets; deploy
   with Run workflow; check its site.
6. **Drop `coldstart_default`**: once no container but the Caddy is on it, remove it from `edge/compose.yml`, deploy
   the edge, and `docker network rm coldstart_default`.
7. **The weekly cache clean-up** from here: copy `host/docker-cache-gc.*` (it is installed already, from lead-engine).

## Later

- Uptime checks on every health URL (an external service, or Uptime Kuma on a second machine; not on this host).
- Backups off the host: restic to a Hetzner Storage Box, for each project's dumps in `/opt/<project>/backups`.
- The server's size: it uses about 1.4 GB of 4 GB with builds moved off it; resize when a new project needs it.
