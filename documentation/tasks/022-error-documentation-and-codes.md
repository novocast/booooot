# 022 — Error documentation & codes

**Phase:** 4 — Reliability
**Status:** 📋 Not started
**Depends on:** 003

## Goal

The "well documented error issues" promise, made real: a living `docs/errors.md` catalog where every `BOOT-xxxx` code has a cause and a fix, and where runtime errors link to it automatically.

## Deliverables

- Central error registry (`lib/errors.sh` from 003) extended with: code → title, cause, fix, and "doctor can fix this" flag.
- `docs/errors.md` generated from the registry (keep registry as source of truth).
- Every error message ends with the doc pointer, e.g. `See docs/errors.md#BOOT-1204`.
- Grouped code ranges: platform/env (1xxx), packages/repos (2xxx), config (3xxx), docker (4xxx), state/manifest (5xxx), generic (0xxx).

## Acceptance criteria

- [ ] Every code in the registry appears in docs; every doc entry exists in the registry.
- [ ] A `booooot doctor` link exists for every "fixable" code.
- [ ] Greppable, consistent format.

## Notes

- Update the registry as codes are introduced during Phases 2–3 — don't wait until Phase 4 to record them.
