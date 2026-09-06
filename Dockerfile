# Teable is pinned to an exact upstream release — never a moving tag like `latest`.
#
# To upgrade: change the tag below to a newer release from
#   https://github.com/teableio/teable/releases
# commit, and push (or redeploy). Migrations run automatically on container
# start (`prisma migrate deploy` — append-only, safe against existing data).
# Read the release notes before bumping, and take a backup first — see the
# "Upgrading" section of the README.
#
# Pinned release: 2026-09-05 (release 2943)
FROM ghcr.io/teableio/teable:release.2026-09-05T15-06-03Z.2943
