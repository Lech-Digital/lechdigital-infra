# Adding a project

1. **DNS**: an A record for the project's domain → 167.233.145.128 (and AAAA → 2a01:4f8:1c0c:6898::1 if wanted).
2. **Routes**: `edge/sites/<project>.caddy`, upstream by container name:

   ```
   api.example.lechdigital.nl {
   	reverse_proxy example-api:8080
   }
   ```
   Open a PR (the Caddyfile is validated), merge, then Actions → Edge → Run workflow.
3. **Compose** in the project repository, `deploy/docker-compose.prod.yml`:
   - a `name:` of its own (two stacks in folders called `deploy` would otherwise collide);
   - every container name prefixed with the project (`example-api`, `example-postgres`): Compose publishes service names
     as DNS aliases on the shared network, and a generic `web` or `db` once took a neighbour's traffic;
   - the image as `example-api:${IMAGE_TAG:-latest}`, so a deploy can pick an exact commit;
   - the public container on the external network `lechdigital_edge`, databases on a private `internal: true` network;
   - a `mem_limit` on every container: the host has 4 GB for everything;
   - a `/health` endpoint that reports the commit (the `GIT_SHA` build argument).
4. **Secrets**: create `/opt/<project>/.env` on the server (generate values there), `chown -R deploy:deploy /opt/<project>`.
5. **Deploy workflow** in the project repository, `.github/workflows/deploy.yml`:

   ```yaml
   name: Deploy (production)
   on:
     push:
       branches: [main]
     workflow_dispatch:
   jobs:
     deploy:
       uses: Lech-Digital/lechdigital-infra/.github/workflows/deploy-app.yml@main
       with:
         app: example
         image: example-api
         health-url: https://api.example.lechdigital.nl/health
       secrets: inherit
   ```
   and the two secrets: `gh secret set DEPLOY_SSH_KEY < ~/.ssh/lechdigital_deploy_ed25519` and
   `ssh-keyscan -t ed25519,rsa 167.233.145.128 | gh secret set DEPLOY_KNOWN_HOSTS`.
