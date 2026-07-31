# 024 — Common-issue fixes library

**Phase:** 4 — Reliability
**Status:** 📋 Not started
**Depends on:** 009, 015–021 (per-service issues)

## Goal

The "common issue solves built in" requirement: a library of known problems and their one-command fixes, surfaced by `booooot doctor --fix`.

## Design

- Each fix: `id`, `matches` (check function), `fix` (function), `risk` (safe/careful), description.
- Fixes live beside the service they belong to (`services/<name>/fixes.sh`).
- `doctor` runs checks (009), maps failures → fixes, and offers `booooot doctor --fix <id>` (or interactive selection).
- Risky fixes (e.g. destructive) always require explicit confirm.

## Example fix list (start)

- `vm.max_map_count` too low (elasticsearch)
- file-descriptor ulimit too low (elasticsearch)
- `nginx -t` failure → show the offending line
- php-fpm not restarted after config change
- mysql root auth via socket only → show correct login command
- node not on PATH after install
- docker not running when docker target chosen

## Acceptance criteria

- [ ] Every fix has a check + fix + risk level and a doc entry (links into 022).
- [ ] `doctor --fix` applies fixes idempotently and confirms before risky ones.
- [ ] No fix ever loses data without explicit confirmation.

## Notes

- Fixes grow from real-world pain encountered during testing (026/027) — keep the list honest, not theoretical.
