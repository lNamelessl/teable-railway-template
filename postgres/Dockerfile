# Postgres 15.4 — the exact version pinned by Teable's own compose files.
# The image default CMD starts postgres; POSTGRES_PASSWORD comes from service
# variables. PGDATA points at a subdirectory of the mounted volume because
# Railway volumes contain a lost+found entry that initdb rejects as a data
# directory — baked in here so deployers never have to set it by hand.
FROM postgres:15.4

ENV PGDATA=/var/lib/postgresql/data/pgdata
