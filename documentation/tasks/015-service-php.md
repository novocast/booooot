# 015 — Service: PHP

**Phase:** 3 — Services
**Status:** 📋 Not started
**Depends on:** 012–014

## Scope

- Multiple versions (8.1–8.4, adjust as supported), side-by-side where sensible.
- CLI + FPM, common extensions (opcache, mbstring, curl, xml, intl, redis, …), extension sets per version.
- Default version selection + `update-alternatives` switching.
- Config options: version, extensions, memory_limit, opcache on/off, FPM pool tuning, default user.
- Common issues (for doctor/024): "extension missing", "version switch not applied", "FPM not restarted after config".

## Acceptance criteria

- [ ] Direct: correct `ondrej/php` (or distro) packages per version; `php -v` matches after install.
- [ ] Docker: official `php` images with extensions via Dockerfile snippets; compose integration.
- [ ] Version switching is documented and idempotent.
- [ ] Catalog metadata (006) updated to match reality.

## Notes

- The reference service — build it first among the seven; others copy its pattern.
