# Teable for Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/teable-1)

Self-host [Teable](https://github.com/teableio/teable) — the open-source, spreadsheet-like
Airtable alternative (21.8k+ ⭐) — on Railway with one click. No hand-copying credentials,
no compose-file editing, no failed first boots.

This template is maintained as a **pinned, deterministic deployment**: the Teable image is
pinned to an exact upstream release, every cross-service credential is wired with Railway
variable references, and the first-boot migration window is covered by a long healthcheck
timeout so deploys don't fail while the database schema is being created.

## What gets provisioned

| Service  | Image                                        | Volume                     | Purpose                                  |
| -------- | -------------------------------------------- | -------------------------- | ---------------------------------------- |
| Teable   | `ghcr.io/teableio/teable` (pinned release)   | `/app/.assets`             | Teable app (web + API + automations)     |
| Postgres | `postgres:15.4` (from [`postgres/`](./postgres)) | `/var/lib/postgresql/data` | Primary datastore (meta + data schemas)  |
| Redis    | `redis:7.2.4` (from [`redis/`](./redis))     | `/data`                    | Cache / session store (AOF persistence)  |

- **Zero deploy-form prompts** — every variable is prewired with Railway references
  (`${{Postgres.POSTGRES_PASSWORD}}`, `${{secret(...)}}`, …). Nothing to copy-paste.
- **All secrets are generated per-deployment by Railway** (`${{secret(…)}}`): Postgres and
  Redis passwords, JWT secret, session secret. No hardcoded credentials anywhere.
- **Migrations run automatically** on every container start. The image entrypoint runs
  `prisma migrate deploy` against both Teable schemas (idempotent, append-only) before the
  web server starts. The healthcheck (`/health`, 300 s timeout) keeps Railway patient
  during first-boot migrations — cold starts legitimately take a few minutes.
- **Data persists** across restarts and redeploys via the three mounted volumes.

> **Scope note:** this deploys the Teable *core* (tables, collaboration, API, automations).
> Teable's AI features (AI fields, App Builder, sandboxes) require a separate runtime plane
> that one-click platforms cannot host — see
> [teableio/teable-deployment](https://github.com/teableio/teable-deployment) for the
> full self-hosted platform. Your data stays compatible if you later migrate.

## Post-deploy setup

1. Open your Teable URL (Railway generates it under the **Teable** service → Settings →
   Networking). First boot runs migrations — give it a few minutes before the UI responds.
2. **Sign up.** The first account created becomes the instance administrator. There is no
   pre-seeded admin account.
3. Optional — **license & instance ID:** for paid self-hosted features, copy the Instance
   ID from the Admin Panel and activate a license key, per
   [Teable's docs](https://help.teable.ai/en/deploy/one-key).
4. Optional — **S3-compatible attachment storage:** attachments are stored on the Teable
   service volume (`/app/.assets`) by default and work out of the box. To store them in
   S3/MinIO instead, attach Railway bucket storage or your own provider and set the
   `BACKEND_STORAGE_*` variables on the Teable service
   ([reference](https://help.teable.ai/en/deploy/docker)). The template boots fine without it.
5. Optional — **SMTP:** set `BACKEND_MAIL_*` variables on the Teable service to enable
   invitation/password-reset emails. Without it, invite users by generating share links.

## Variables (reference contract)

| Variable (Teable service)      | Value                                                                                                        |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------ |
| `PUBLIC_ORIGIN`                | `https://${{RAILWAY_PUBLIC_DOMAIN}}`                                                                          |
| `PRISMA_DATABASE_URL`          | `postgresql://postgres:${{Postgres.POSTGRES_PASSWORD}}@${{Postgres.RAILWAY_PRIVATE_DOMAIN}}:5432/postgres`     |
| `BACKEND_CACHE_REDIS_URI`      | `redis://default:${{Redis.REDIS_PASSWORD}}@${{Redis.RAILWAY_PRIVATE_DOMAIN}}:6379/0`                          |
| `SECRET_KEY`                   | `${{secret(48, …)}}` — per-deploy generated                                                                   |
| `BACKEND_JWT_SECRET`           | `${{secret(48, …)}}` — per-deploy generated                                                                   |
| `BACKEND_SESSION_SECRET`       | `${{secret(64, …)}}` — per-deploy generated                                                                   |

`PRISMA_DATABASE_URL` and `BACKEND_CACHE_REDIS_URI` are exactly the variable names Teable's
own compose files and backend env-validation schema use — nothing was guessed.

> Why `BACKEND_JWT_SECRET` and `BACKEND_SESSION_SECRET` are set explicitly: Teable's secret
> resolver falls back to *publicly known* built-in defaults unless these dedicated variables
> are present (setting only `SECRET_KEY` does not override those defaults). Generating them
> per-deploy is what makes your instance's tokens and sessions actually private.

## Upgrading (bumping the pinned tag)

The version lives in exactly one place: the `FROM` line of the
[`Dockerfile`](./Dockerfile). To upgrade:

1. **Back up first.** Railway dashboard → Postgres service → Volumes → *Backups* (or
   `pg_dump` over Railway private networking). Upgrades apply sequential DB migrations;
   a backup is your rollback if one fails.
2. Skim the release notes of the target release:
   <https://github.com/teableio/teable/releases>
3. Edit the tag in `Dockerfile`, commit, push (or click *Redeploy* if you edited in the
   dashboard's connected repo). Railway rebuilds, migrations run on start, and the
   healthcheck holds the deploy until Teable is actually serving.
4. **Do not roll back to an older tag after migrations ran** — downgrades through Prisma
   migrations are not supported. Roll back by restoring the backup taken in step 1 instead.

Because the tag is pinned, redeploys never silently pull a newer version — the failure mode
that breaks `latest`-based Teable templates when upstream ships multiple releases a day.

## Troubleshooting

**Deploy fails at healthcheck / app crash-loops on boot**
First boots run migrations and can take 1–3 minutes — this is normal and the 300 s
healthcheck timeout exists for exactly this. If it still fails, check the Teable deploy
logs: `railway logs -d -s Teable` (or the Deployments view).

**`Can't reach database server` / Prisma connection errors**
- Check the Postgres service is actually deployed (not crashed) and both services are in
  the same environment/region — Teable reaches it over Railway private networking
  (`Postgres.RAILWAY_PRIVATE_DOMAIN`), which doesn't work across environments.
- Verify the variable is untouched: `PRISMA_DATABASE_URL` must reference
  `${{Postgres.POSTGRES_PASSWORD}}`, not a pasted password.
- Postgres attaches a volume at `/var/lib/postgresql/data`. If you deleted that volume,
  the DB re-initializes empty on next boot (data loss, not a connection error).

**`Cache config error` / Redis auth errors**
`BACKEND_CACHE_REDIS_URI` must keep the shape
`redis://default:${{Redis.REDIS_PASSWORD}}@${{Redis.RAILWAY_PRIVATE_DOMAIN}}:6379/0`. The
`default:` username and the password reference matter — Redis is started with
`--requirepass $REDIS_PASSWORD`, so a pasted/mismatched password fails auth.

**App boots but attachments/uploaded files vanish after redeploy**
That means the `/app/.assets` volume was removed or unmounted. Keep the volume attached;
that's where uploads and local files live.

**Upgrade failed mid-migration**
Check the deploy logs for the failing migration, then restore the Postgres volume backup
from before the upgrade and pin the previous release tag in `Dockerfile`. Upgrades are
append-only migrations — never force-downgrade the image while keeping migrated data.

## Why this template exists

The most popular Teable template on the Railway marketplace failed ~52% of recent deploys
(48% success rate over 988 projects as of Sept 2026) and Teable deprecated its own one-click
templates. The usual cause is version drift: `latest`-based deployments break when upstream
(which ships several releases a day) changes its env contract or migrations. This template
pins the image, uses only the current documented env contract, and survives fresh boots,
redeploys with existing volumes, and restarts — verified with repeated fresh deploys.

## Repo layout

```
Dockerfile          # pinned FROM ghcr.io/teableio/teable:<release> — the upgrade surface
postgres/Dockerfile # postgres:15.4 + PGDATA baked to a volume subdirectory (Railway
                    #   volumes contain a lost+found entry initdb refuses as a datadir)
redis/Dockerfile    # redis:7.2.4 with a shell-form CMD so --requirepass expands
                    #   $REDIS_PASSWORD from the environment at container start
railway.json        # healthcheck (/health, 300s), restart policy, Dockerfile builder
```

All three services are built from this repo so every pin is visible and updatable in
code, and the published template stays repo-sourced (updatable, ejectable — never a
faceless image).

## License

MIT, like the upstream project. Teable itself is AGPL-3.0 —
see [teableio/teable](https://github.com/teableio/teable).
