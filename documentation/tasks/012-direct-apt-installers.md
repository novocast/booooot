# 012 — Direct apt installers

**Phase:** 2 — Install engine
**Status:** 📋 Not started
**Depends on:** 011

## Goal

The `direct` (tin) target: install software natively on the host via **apt**, including the repo/PPA setup some services require. Debian/Ubuntu only.

## Shared machinery (`lib/apt.sh`)

- `apt_update`, `apt_install <pkgs…>` (idempotent — skip if already satisfied).
- Repo/PPA management: add keys, sources (e.g. `ondrej/php`, `nodesource`, Elasticsearch & Varnish official repos) with rollback on failure.
- Package-version helpers: resolve "8.3" → concrete apt package names (`php8.3`, `php8.3-fpm`, …).
- Pre/post apt hooks for the services that need them.

## Acceptance criteria

- [ ] Installing any catalog service via direct target resolves to correct packages for the chosen version and distro.
- [ ] Re-running is a no-op when already installed (idempotent), with clear "already installed" messaging.
- [ ] Repo/PPA failures surface with a `BOOT-` code and the exact apt error logged.
- [ ] All work done under sudo when required, non-interactively where possible.

## Notes

- Version-specific package lists live with each service (015–021), not in this task.
- Respect `DEBIAN_FRONTEND=noninteractive` where safe to avoid interactive prompts.
