#!/usr/bin/env bash
#
# setup-deploy-user.sh: the `deploy` user GitHub Actions logs in as (once per host). Run from the repository root:
#
#   ./host/setup-deploy-user.sh ~/.ssh/lechdigital_deploy_ed25519.pub coo pureprep corechoice cultofcomfort coldstart
#
# It may run docker (which is root-equivalent: the key is the secret that matters, and it lives only in GitHub's
# secrets and on your Mac), and it owns /opt/lechdigital-edge and each project's folder, .env included, so compose can
# read the secrets. The key may not forward ports or agents, or open a terminal.
set -euo pipefail
HOST="${EDGE_HOST:-lechdigital-prod}"
PUB="${1:?the public key file}"; shift
key="$(cat "$PUB")"
ssh "$HOST" "set -e
  id deploy >/dev/null 2>&1 || useradd --create-home --shell /bin/bash deploy
  usermod -aG docker deploy
  install -d -m 700 -o deploy -g deploy /home/deploy/.ssh
  printf '%s\n' 'no-port-forwarding,no-agent-forwarding,no-X11-forwarding,no-pty $key' > /home/deploy/.ssh/authorized_keys
  chown deploy:deploy /home/deploy/.ssh/authorized_keys && chmod 600 /home/deploy/.ssh/authorized_keys
  mkdir -p /opt/lechdigital-edge && chown -R deploy:deploy /opt/lechdigital-edge
  for app in $*; do [ -d /opt/\$app ] && chown -R deploy:deploy /opt/\$app && echo \"  /opt/\$app → deploy\"; done
  echo 'deploy user ready'"
