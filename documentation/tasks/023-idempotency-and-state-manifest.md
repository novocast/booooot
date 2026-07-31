# 023 — Idempotency & state manifest

**Phase:** 4 — Reliability
**Status:** 📋 Not started
**Depends on:** 008, 011

## Goal

Formalise the state model so booooot is **safe to re-run** and the status view (008) is trustworthy. Define how states transition and what "installed / configured / running / failed" mean.

## Manifest semantics

- States per service: `absent` → `planned` → `installing` → `installed` → `configured` → `running` (with `failed`/`stale` side states).
- Every state change is written by the engine (011) only after success.
- Idempotency rules per operation:
  - `install` when `installed` → skip with reason ("already installed (8.3)").
  - `install` when `failed` → re-attempt with fresh run, old state cleared.
  - `uninstall` when `absent` → no-op with friendly message.
- Config apply updates `configured` + stores applied-options snapshot for `doctor` diffs.

## Acceptance criteria

- [ ] Re-running any operation twice produces identical end state (and clear "already done" output).
- [ ] Failed runs never leave a half-written manifest.
- [ ] Status view (008) reflects manifest truth; doctor (009) can flag `installed but not running`.

## Notes

- Concurrency: a simple lock file (`~/.booooot/.lock`) prevents two booooot runs colliding.
- Credential storage security reviewed here (see 016/017).
