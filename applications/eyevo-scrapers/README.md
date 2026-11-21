# Eyevo scrapers (namespace `eyevo-scrapers`)

Scrapers of the Eyevo app (repo VegaPunkLabs/pokemontcg) as containers from GHCR
(`ghcr.io/vegapunklabs/eyevo-<scraper>`, linux/arm64 + amd64), on the 4 GB nodes
`node1` / `worker2` only. The full runbook (inventory, cutover, rollback, logs) is
`docs/operations/k3s-scrapers.md` in that repo.

| Workload | What | State |
|---|---|---|
| CronJob `v6-prices-freshness` | 11:00 Berlin: Telegram if the v6 manifest's prices were not refreshed today | active |
| Deployment `poketrace` | Poketrace price daemon (from the Hetzner box) | replicas 0 until cutover |
| CronJob `scrydex` | Scrydex importer, 00:30 UTC (from the Hetzner timer) | suspended until cutover |
| CronJob `tcgplayer` | TCGplayer batch scraper, Berlin times, quiet hours 04–10 | suspended until cutover |

Deploys: the app repo's workflow `scraper-images.yml` builds on push and sets the new
image through the service account `eyevo-deployer` (rbac.yaml: patch deployments and
cronjobs in this namespace only, no secrets). Its token and the cluster CA are the
GitHub secrets `KUBE_EYEVO_DEPLOY_TOKEN` / `KUBE_EYEVO_CA`; the runner reaches the API
through an SSH forward over the Mac mini. Deploys never change replicas or suspend.

Secrets are provisioned out of band (stream the values, never print or commit them):
`eyevo-telegram` (exists), `ghcr-pull` (docker-registry, a read:packages token; needed
before any scraper image can be pulled), `eyevo-poketrace`, `eyevo-scrydex`,
`eyevo-tcgplayer` (keys listed in the runbook).

```sh
make tunnel
kubectl --context default-via-mini-tunnel apply -k applications/eyevo-scrapers
kubectl --context default-via-mini-tunnel -n eyevo-scrapers get cronjobs,jobs,pods
make tunnel-stop
```
