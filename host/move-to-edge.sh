#!/usr/bin/env bash
#
# move-to-edge.sh: after edge/cutover.sh, moves the RUNNING containers from Coldstart's network to lechdigital_edge,
# without rebuilding or restarting anything, and points each project's compose copy on the server at the new network,
# so a restart keeps it. Each project's own repository has the same change (its "lechdigital-edge" PR).
#
#   ./host/move-to-edge.sh [path to lead-engine's new docker-compose.prod.yml]
#
# Order: connect to the new network, check every site, only then disconnect from the old one. Coldstart's own
# containers keep coldstart_default: it is that stack's private network (web ↔ db), not the shared one any more.
set -euo pipefail
HOST="${EDGE_HOST:-lechdigital-prod}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COLDSTART_COMPOSE="${1:-}"
PUBLIC=(coo-api pureprep-web corechoice-api cultofcomfort-api coldstart-web-1 coldstart-umami-1)
MOVED=(coo-api pureprep-web corechoice-api cultofcomfort-api)

ssh "$HOST" "set -e
  docker ps --format '{{.Names}}' | grep -qx lechdigital-caddy || { echo 'Run ./edge/cutover.sh --confirm first.' >&2; exit 1; }
  for c in ${PUBLIC[*]}; do
    if docker network inspect lechdigital_edge --format '{{range .Containers}}{{.Name}} {{end}}' | grep -qw \$c; then echo \"  \$c already on lechdigital_edge\";
    else docker network connect lechdigital_edge \$c && echo \"  \$c → lechdigital_edge\"; fi
  done
  for app in coo pureprep corechoice cultofcomfort; do
    f=/opt/\$app/deploy/docker-compose.prod.yml
    if grep -q coldstart_default \$f; then cp -p \$f \$f.bak-before-edge && sed -i 's/coldstart_default/lechdigital_edge/g' \$f && echo \"  \$f → lechdigital_edge\"; fi
  done"
if [ -n "$COLDSTART_COMPOSE" ]; then
  ssh "$HOST" 'cp -p /opt/coldstart/docker-compose.prod.yml /opt/coldstart/docker-compose.prod.yml.bak-before-edge'
  scp -q "$COLDSTART_COMPOSE" "$HOST:/opt/coldstart/docker-compose.prod.yml" && echo "  /opt/coldstart/docker-compose.prod.yml: no caddy, web and umami on lechdigital_edge"
fi

echo "==> Every site, through the new network"
fail=0
for h in $(grep -ho '^[a-z0-9.-]*\.[a-z]* {' "$ROOT"/edge/sites/*.caddy | tr -d ' {'); do
  code=$(curl -s -o /dev/null -m 10 -w '%{http_code}' "https://$h" || true); printf '  %-36s %s\n' "$h" "$code"
done

echo "==> Leaving the old network"
ssh "$HOST" "for c in ${MOVED[*]}; do docker network disconnect coldstart_default \$c 2>/dev/null && echo \"  \$c left coldstart_default\" || true; done
  echo '  still on coldstart_default:'; docker network inspect coldstart_default --format '{{range .Containers}}    {{.Name}}{{println}}{{end}}'"
echo "Next: merge lechdigital-infra's PR that takes coldstart_default off the edge (only Coldstart's own containers and the Caddy should be listed above)."
