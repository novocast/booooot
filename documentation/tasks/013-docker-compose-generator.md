# 013 — Docker compose generator

**Phase:** 2 — Install engine
**Status:** 📋 Not started
**Depends on:** 011

## Goal

The `docker` target: generate and manage `docker-compose.yml` setups for each service, driven by the same plans/config options as the direct target.

## Deliverables

- `lib/docker.sh`: compose file generation from catalog + plan; `docker compose up -d` wrapper; health check; logs tail.
- Per-service compose snippets (images, ports, volumes, env from config options) in the service modules.
- A `booooot docker ps`-style status mapping back into the manifest (container up/running → status view).
- Port-conflict detection before generating.

## Acceptance criteria

- [ ] `booooot install mysql --target docker` produces a valid, documented compose file and starts it.
- [ ] Config options (user, password, version, ports) flow into env/compose correctly and are kept out of committed files (`.env` handling).
- [ ] Re-running regenerates/updates cleanly without destroying data volumes.
- [ ] Works on the test VM and in CI without needing a real server.

## Notes

- Use official images and pin versions.
- Think about a `booooot-compose/` working directory convention (e.g. `~/.booooot/compose/<service>/`).
