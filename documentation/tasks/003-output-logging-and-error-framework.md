# 003 — Output, logging & error framework

**Phase:** 0 — Foundation
**Status:** ✅ Done (initial pass — doc linkage lands in 022)
**Depends on:** 001, 002

## Goal

A single, consistent way for every part of booooot to talk to the user and to record what happened — the foundation for the "well documented error issues" requirement.

## Deliverables

- **Log levels:** debug / info / ok / warn / error / fatal, each styled via the colour system.
- **Console + file logging:** every run appends to a log (e.g. `~/.booooot/logs/booooot.log`); console shows progress, file shows detail.
- **Error code scheme:** `BOOT-xxxx`, e.g. `BOOT-1001 unsupported distro`, `BOOT-2001 package not found`. A `die <code> <message>` helper that prints the code, writes the log, and suggests the doc link.
- **Dry-run engine:** `--dry-run` prints what *would* happen without doing it — the interface phase's primary mode.
- **Progress/step helpers:** numbered step output (e.g. `[3/7] Installing nginx…`) for transparency.

## Acceptance criteria

- [ ] `booooot` never exits with an unexplained failure — every failure carries a `BOOT-` code.
- [ ] Log file written on every run; console stays clean and colourful.
- [ ] `--dry-run` available globally and shows a plan without side effects.
- [ ] Mapping of codes → docs/errors.md (built in Phase 4, 022).

## Notes

- Error codes are the backbone of the debugging story; keep the registry central (`lib/errors.sh`).
- Machine-readable mode (`--json`) is a future option — design codes to be stable.
