# 025 — Automated test suite (bats)

**Phase:** 5 — Testing platform
**Status:** 📋 Not started
**Depends on:** 004–010 (unit/interface), then grows with every phase

## Goal

Automated tests for everything that can be tested without a real server: flag parsing, catalog, dry-run plans, status rendering, error codes, template rendering.

## Approach

- **bats-core** as the framework (bash-native, no extra runtime).
- Unit tests: `lib/` functions in isolation (source the file, call functions).
- Interface tests: run `booooot ... --dry-run` and assert on stdout/exit codes — this is also the surface LLM/scripted testing uses, so keep output stable.
- Golden-file tests for `--dry-run` plans and `status` rendering.
- No tests touch the real system: everything in this suite is dry-run / temp-dir / fake-state-file.

## Acceptance criteria

- [ ] `make test` (or `tests/run.sh`) runs the full suite locally in git bash and CI.
- [ ] Every interface task (004–010) has at least one automated test.
- [ ] New phases add tests as they land (services get integration-style tests on the VM, 026).

## Notes

- Assert on the same stable output lines that LLM testing relies on — stability is a feature.
