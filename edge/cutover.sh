#!/usr/bin/env bash
#
# cutover.sh: the one-time move from Coldstart's Caddy (coldstart-caddy-1, config in /opt/coldstart) to the edge
# (lechdigital-caddy, config in /opt/lechdigital-edge). Run from the repository root:
#
#   ./edge/cutover.sh --confirm
#
# The edge reuses Coldstart's certificate volumes, so nothing is issued again. HTTPS is down for the few seconds between
# stopping the old Caddy and starting the new one. If the new one does not start, the old one is started again.
# The old container is stopped and kept (restart policy "no"), for a rollback: ./edge/cutover.sh --rollback
set -euo pipefail
HOST="${EDGE_HOST:-lechdigital-prod}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ "${1:-}" = "--rollback" ]; then
  ssh "$HOST" 'cd /opt/lechdigital-edge && docker compose down; docker update --restart=unless-stopped coldstart-caddy-1 && docker start coldstart-caddy-1'
  echo "Rolled back to coldstart-caddy-1."
  exit 0
fi
if [ "${1:-}" != "--confirm" ]; then
  echo "This swaps the Caddy that serves every site on $HOST. Re-run with --confirm." >&2
  exit 2
fi

sites=$(grep -ho '^[a-z0-9.-]*\.[a-z]* {' "$ROOT"/edge/sites/*.caddy | tr -d ' {')
check() { for h in $sites; do printf '  %-36s %s\n' "$h" "$(curl -s -o /dev/null -m 10 -w '%{http_code}' "https://$h")"; done; }

echo "==> Before"; check
ssh "$HOST" 'mkdir -p /opt/lechdigital-edge'
rsync -rlptz --delete "$ROOT/edge/" "$HOST:/opt/lechdigital-edge/"
ssh "$HOST" "id deploy >/dev/null 2>&1 && chown -R deploy:deploy /opt/lechdigital-edge || true"
ssh "$HOST" 'set -e; cd /opt/lechdigital-edge && docker compose pull -q
  docker update --restart=no coldstart-caddy-1 >/dev/null
  docker stop coldstart-caddy-1 >/dev/null
  if ! docker compose up -d; then
    echo "EDGE FAILED TO START: rolling back" >&2
    docker compose down || true
    docker update --restart=unless-stopped coldstart-caddy-1 >/dev/null; docker start coldstart-caddy-1 >/dev/null
    exit 1
  fi'
sleep 5
echo "==> After"; check
echo "Compare the two lists. To go back: ./edge/cutover.sh --rollback"
