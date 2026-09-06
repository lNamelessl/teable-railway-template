# Redis 7.2.4 — the exact version pinned by Teable's own compose files.
#
# Shell-form CMD so that $REDIS_PASSWORD (a Railway-generated secret set on the
# service) is expanded from the container environment at start — this avoids
# depending on how the platform expands custom start commands.
# AOF persistence keeps the cache/session store across restarts; the volume is
# mounted at /data by the Railway template.
FROM redis:7.2.4

CMD ["sh", "-c", "exec redis-server --appendonly yes --requirepass \"$REDIS_PASSWORD\""]
