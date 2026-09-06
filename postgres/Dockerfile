# Postgres 15.4 — the exact version pinned by Teable's own compose files.
# The image default CMD starts postgres; POSTGRES_PASSWORD / PGDATA come from
# service variables (PGDATA points at a subdirectory of the mounted volume
# because Railway volumes contain a lost+found entry that initdb rejects).
FROM postgres:15.4
