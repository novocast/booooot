# 007 — Install wizard & dry-run flow

**Phase:** 1 — Interface *(current focus)*
**Status:** ✅ Done
**Depends on:** 004, 005, 006

## Goal

The end-to-end **install flow** — in both wizard and flag form — that plans an install, shows the plan, and (in this phase) stops at "would install". Nothing is actually installed yet; this proves the interface.

## Flow (both modes produce the same result)

1. Pick service (wizard menu / `install <service>` flag).
2. Pick version.
3. Pick target: **direct (tin)** / **docker** / **vm**.
4. Answer the config questions for that service (from catalog).
5. **Summary screen:** "booooot would install PHP 8.3 → docker, with: opcache=on, memory=512M…"
6. Confirm → exit with `BOOT-0000 dry-run complete` and no side effects.

## Acceptance criteria

- [x] Wizard path and flag path produce identical plans for identical inputs.
- [x] `--dry-run` is implied (and default) in this phase; output clearly says nothing was changed.
- [x] Plans are reproducible: same input → same output (important for LLM/scripted testing).
- [x] Cancel/quit at any step exits cleanly with a friendly message.

## Notes

- **Implemented:** `lib/flow.sh` (wizard install/uninstall with back-nav at every step) + `lib/plan.sh` (canonical plan printer shared by both paths). Flag mode defaults `--version` to the catalog default, validates everything against the catalog, and canonicalises multi-select configs so plans are order-independent. `--plan-file <path>` dumps a plain plan for test assertions. Cancel/quit → `BOOT-1005` note, never an error.
- The plan printer (`lib/plan.sh`) will be reused by the real engine in Phase 2 — keep plan format stable.
- Consider a `--plan-file out.txt` to dump plans for test assertions. → **done** (`--plan-file`).
