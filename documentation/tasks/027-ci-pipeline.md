# 027 — CI pipeline

**Phase:** 5 — Testing platform
**Status:** 📋 Not started
**Depends on:** 025 (bats), grows with later phases

## Goal

Continuous integration so booooot is tested on every change, on real Ubuntu runners — the closest thing to a real server without a VM.

## Approach (draft)

- **GitHub Actions**, `ubuntu-latest` (24.04) runner(s).
- Jobs:
  1. **Lint**: shellcheck on all committed bash + bats syntax check.
  2. **Unit/interface tests**: the full bats suite (025), git-bash-portable subset plus full on Linux.
  3. **Dry-run smoke**: run `booooot install <each service> --dry-run` and assert plan output.
  4. **Container integration** (once engine lands): systemd-enabled container job for direct installs; docker target job.
  5. **Docs check**: error registry ↔ docs/errors.md in sync (022).

## Acceptance criteria

- [ ] CI is green on every push/PR.
- [ ] Failing lint or tests blocks merge.
- [ ] CI exercises both flag mode and (headless) wizard entrypoints.

## Notes

- Keep CI jobs fast and layered: lint/unit first, integration slower.
- Secrets: none expected in CI (all tests use throwaway/fake state).
