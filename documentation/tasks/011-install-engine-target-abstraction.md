# 011 — Install engine: target abstraction

**Phase:** 2 — Install engine
**Status:** ✅ Done
**Depends on:** 007

## Goal

The core engine that turns a **plan** (from 007) into actions, behind a **target abstraction**: `direct` (tin), `docker`, `vm`. Each service provides a strategy per target; the engine executes it, logs every step, and records the result into the state manifest.

## Design

- Plan → target resolver → strategy → executor → manifest update.
- `lib/engine.sh`: orchestrates; emits step progress via the 003 framework; honours `--dry-run` (real no-op) vs live mode.
- Strategy interface per service: `install`, `uninstall`, `config_apply`, `status` (probe), each target-aware.
- Idempotency hooks: strategies check current state before acting (formalised in 023).

## Acceptance criteria

- [x] Same plan executes through direct and docker paths with consistent step output.
- [x] Every step either succeeds, fails with a `BOOT-` code, or is skipped-with-reason (idempotent).
- [x] Manifest updated only after success; failed runs leave it untouched (or clearly marked).
- [x] `--dry-run` works at engine level (no side effects, same output shape as live).

## Notes

- VM target is stubbed here and fleshed out with the test VM work (026).
- Keep the executor dumb and the strategies responsible — mirrors EasyEngine's modularity.
