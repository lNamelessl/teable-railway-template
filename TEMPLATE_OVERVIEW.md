# Teable — Open-Source Airtable Alternative, One Click on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/vSQ1tV)

Self-host [Teable](https://github.com/teableio/teable) (21.8k+ ⭐) — the spreadsheet-like
database your team already knows how to use — with zero manual setup. This template
provisions the **exact stack Teable's own maintainers specify** (their reference compose
files): the Teable app, PostgreSQL 15.4, and Redis 7.2.4, wired together with Railway
variable references so you never copy a password by hand.

**Why this template is different:** every variable is prewired with expression references
(`https://railway.com/deploy/vSQ1tV` generates fresh secrets per deployment), the Teable
image is **pinned to an exact upstream release** (never `latest`, so version drift can't
break your deploys), first-boot database migrations are covered by a 300-second
healthcheck, and all three services store data on persistent volumes. Fresh boot, redeploy,
and restart are all verified to preserve your data.

## What you get

| Service  | Image                                      | Volume                     | Purpose                              |
| -------- | ------------------------------------------ | -------------------------- | ------------------------------------ |
| Teable   | `ghcr.io/teableio/teable` (pinned release) | `/app/.assets`             | Tables, collaboration, API, automations |
| Postgres | `postgres:15.4`                            | `/var/lib/postgresql/data` | Primary datastore (Prisma migrations run on boot) |
| Redis    | `redis:7.2.4` (AOF persistence)            | `/data`                    | Cache and session store              |

- **Zero deploy-form prompts** — click deploy, drink coffee, open your Teable URL.
- **Automatic admin** — the first account you create in the UI is the instance admin.
- **Migrations run automatically** on every start (idempotent `prisma migrate deploy`).
- **Attachments** store on the Teable volume and work out of the box; bring your own
  S3/MinIO later via the `BACKEND_STORAGE_*` variables if you want.
- **Scope:** Teable core (tables, collaboration, API, automations). Teable's AI features
  need a separate runtime plane one-click platforms can't host — see
  [teableio/teable-deployment](https://github.com/teableio/teable-deployment).

## Cost expectations

Teable is a real full-stack app (Next.js + NestJS + Prisma) and is memory-hungry:
**plan for at least 1 GB of RAM on the Teable service** (2 GB is comfortable for teams).
On Railway's usage-based pricing, a lightly-used instance typically lands around
**$10–25/month** total: Teable dominates the bill (RAM + vCPU while running), Postgres
and Redis are small (512 MB volumes are fine for months of typical use). Railway charges
only for what you consume, and you can scale each service's RAM independently in
Settings → Config.

## Post-deploy setup

1. Open your Railway project and click the Teable service's public domain. **First boot
   runs database migrations — the app can take 1–3 minutes to answer.** This is normal;
   the template's 300-second healthcheck exists exactly for this window.
2. Click **Sign up** — the first account becomes the instance administrator.
3. Invite teammates from inside Teable (share links work without SMTP; set the
   `BACKEND_MAIL_*` variables on the Teable service if you want email invites).
4. Optional: attach S3-compatible storage for attachments (`BACKEND_STORAGE_*`
   variables), or activate a license key via the Admin Panel for paid features
   ([Teable's docs](https://help.teable.ai/en/deploy/one-key)).

# Deploy and Host

## About Hosting

Hosting Teable yourself means your tables, records, and attachments never leave
infrastructure you control, and you can use it with unlimited users at no per-seat cost.
This template runs the community-edition image Teable publishes, pinned to the exact
release [`release.2026-09-05T15-06-03Z.2943`](https://github.com/teableio/teable/releases)
(one bump = one line in the repo's `Dockerfile`). PostgreSQL 15.4 and Redis 7.2.4 match
Teable's own reference compose file — variable names (`PRISMA_DATABASE_URL`,
`BACKEND_CACHE_REDIS_URI`, `PUBLIC_ORIGIN`, …) are taken from Teable's backend env
validation schema, not guessed. All three services keep state on Railway volumes, so
deploys and restarts don't lose data.

## Why Deploy

The previously popular Teable template on Railway failed over half of recent deploys, and
Teable has deprecated its own one-click templates. The usual killer is version drift:
`latest`-based images break when upstream (which ships several releases per day) changes
its env contract or migrations. This template pins the version, wires every credential
with Railway references generated per-deployment, and survives the failure modes that
kill hand-rolled Teable deploys: first-boot migration timeouts, Redis `WRONGPASS` from
hand-copied passwords, and empty databases after redeploys. Deploying through this
template gets you a stack that's been verified end-to-end: signup, base creation, cell
edits, restart, and redeploy with data intact.

## Common Use Cases

- **Team databases without per-seat fees** — CRM, project tracking, inventory, and
  content calendars with real-time collaboration, unlimited users on your own instance.
- **Internal tools and admin panels** — Teable's table/view/permission model plus its
  REST API (an OpenAPI spec ships with your instance at `/docs`) makes it a backend for
  internal apps and automations.
- **Self-hosted data residency** — keep customer or regulated data on infrastructure you
  control instead of a SaaS spreadsheet, with PostgreSQL as the open, dumpable storage
  layer.
- **Airtable migration landing zone** — import existing Airtable CSVs/bases into an
  open-source stack you can back up, extend, and vendor-neutral-ly host.

## Dependencies for

### Deployment Dependencies

- **PostgreSQL 15.4** (`postgres:15.4`, Railway volume at `/var/lib/postgresql/data`,
  `PGDATA` baked to a `pgdata` subdirectory because Railway volumes contain a
  `lost+found` entry) — wired via `PRISMA_DATABASE_URL = postgresql://postgres:${{Postgres.POSTGRES_PASSWORD}}@${{Postgres.RAILWAY_PRIVATE_DOMAIN}}:5432/postgres`.
- **Redis 7.2.4** (`redis:7.2.4`, AOF persistence, volume at `/data`, started with
  `--requirepass`) — wired via `BACKEND_CACHE_REDIS_URI = redis://default:${{Redis.REDIS_PASSWORD}}@${{Redis.RAILWAY_PRIVATE_DOMAIN}}:6379/0`.
- **Per-deployment secrets** generated by Railway: `POSTGRES_PASSWORD`, `REDIS_PASSWORD`,
  `SECRET_KEY`, `BACKEND_JWT_SECRET`, `BACKEND_SESSION_SECRET`. Note the JWT and session
  secrets are set explicitly because Teable otherwise falls back to publicly known
  built-in defaults — this is what keeps your instance's tokens private.
- **Public domain** on the Teable service (auto-provisioned), referenced as
  `PUBLIC_ORIGIN = https://${{RAILWAY_PUBLIC_DOMAIN}}`.
- No deploy-time inputs are required — there is nothing to type, ever.

## Troubleshooting

**Deploy stuck or fails in the first minutes** — first boot runs Prisma migrations
(1–3 minutes is normal). Check the Teable service's deploy logs; the healthcheck path is
`/health`. If it crash-loops, read the log line above the stack trace.

**`Can't reach database server` / Prisma errors (DB connection)** — the Teable service
reaches Postgres over Railway private networking; both services must be in the same
environment and region. Verify `PRISMA_DATABASE_URL` still uses the
`${{Postgres.POSTGRES_PASSWORD}}` reference (not a pasted password) and that the Postgres
volume is still attached — deleting it re-initializes an empty database.

**`WRONGPASS` / `Cache config error` (cache connection)** — Redis runs with
`--requirepass $REDIS_PASSWORD`; the URI must keep the `redis://default:` username and the
`${{Redis.REDIS_PASSWORD}}` reference. If you rotated `REDIS_PASSWORD` manually, also
redeploy Redis (its start command reads the variable at boot).

**Upgrading Teable (version upgrades)** — the version lives in one place: the `FROM` line
of the [repo's Dockerfile](https://github.com/lNamelessl/teable-railway-template/blob/main/Dockerfile).
Back up the Postgres volume first (Railway dashboard → Postgres → Backups, or `pg_dump`),
skim the target [release notes](https://github.com/teableio/teable/releases), bump the
tag, and redeploy. Never roll back to an older image after migrations ran — restore the
backup instead.
