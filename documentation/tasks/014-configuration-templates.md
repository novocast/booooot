# 014 — Configuration templates

**Phase:** 2 — Install engine
**Status:** 📋 Not started
**Depends on:** 011

## Goal

Turn the "useful configurations during install" requirement into a template system: after install, render config files from templates using the plan's config options, then restart/reload the service.

## Deliverables

- `lib/template.sh`: variable substitution engine (no external templating dependency), with validation and a diff preview before applying.
- Template library per service under `services/<name>/templates/` (php-fpm pools, mysql/my.cnf, nginx vhosts, elasticsearch jvm.options, varnish VCL, …).
- "Sane defaults" curated per service; user choices from the wizard override.
- Config apply is part of the engine flow (011) and records state → manifest (config applied / not).

## Acceptance criteria

- [ ] Applying config is idempotent and reversible (backups taken; `--restore` or documented rollback).
- [ ] Invalid user values are caught before render with a `BOOT-` code.
- [ ] Dry-run shows a diff of what would change, not just "would write files".

## Notes

- This is where the "specific useful configurations" promise lives — make the defaults genuinely good, not just present.
