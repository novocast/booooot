# 006 — Service catalog metadata

**Phase:** 1 — Interface *(current focus)*
**Status:** ✅ Done
**Depends on:** 001

## Goal

A single source of truth describing every service booooot can manage — what the wizard menus and the flag parser both consume. Nothing here performs installs yet; it only describes.

## Catalog contents (all 7 services)

| Service | Notes |
|---------|-------|
| `php` | Multiple versions (e.g. 8.1–8.4), per-version package sets, extensions |
| `mysql` | Server + client, version choices, root password handling |
| `postgresql` | Server + client, version choices |
| `nginx` | Version, site/vhost scaffolding |
| `node` | Node + **pnpm** (corepack or standalone), LTS vs current |
| `elasticsearch` | Version, memory/JVM settings |
| `varnish` | Version, cache config basics |

## Per service, metadata shape (draft)

- name, human label, description (for menus/help)
- available versions
- supported targets (`direct`, `docker`, `vm`)
- configuration options: key, label, type (`select`/`bool`/`string`/`int`), default, choices
- default config values

## Deliverables

- Catalog defined in `services/<name>/meta.sh` + registered by an index (`services/index.sh`).
- `booooot list` renders the catalog (services, versions, targets).

## Acceptance criteria

- [x] `booooot list` shows all 7 services with versions and targets.
- [x] Wizard menus and `--config` flag validation both read from the same catalog (no duplication).
- [x] Unknown service / version fails with a `BOOT-` code listing valid choices.

## Notes

- **Implemented:** `services/<name>/meta.sh` per service, registered via `services/index.sh` (`BOOT_CATALOG` flat metadata + `BOOT_CATALOG_CFG` config specs `label|type|default|choices`; types: `select`/`bool`/`string`/`int`/`checklist`). `booooot list`, the wizard menus, and `--version`/`--config` validation all consume this index — no duplication. Unknown service → `BOOT-1004`; unknown version → `BOOT-3002`; unknown config key → `BOOT-3003`; invalid value → `BOOT-3004` (all list valid choices).
- This file becomes the contract for Phases 2–3; flesh version lists/config options when each service task (015–021) is done.
