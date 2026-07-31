# 017 — Service: PostgreSQL

**Phase:** 3 — Services
**Status:** 📋 Not started
**Depends on:** 012–014

## Scope

- PostgreSQL server + client; version choice.
- User/database creation helpers (`booooot`-level convenience: create db + user from the wizard).
- Config options: version, port, superuser password, locale, memory/`shared_buffers` preset.
- Common issues (doctor/024): "peer auth failed", "port conflict", "cluster not started".

## Acceptance criteria

- [ ] Direct: installs, initialises a cluster, creates a role/database when asked.
- [ ] Docker: official image, env-based creds, persistent volume.
- [ ] Idempotent and credential-safe (mirrors 016).

## Notes

- Remember Debian/Ubuntu cluster management (`pg_ctlcluster`) differs from upstream tarball layouts.
