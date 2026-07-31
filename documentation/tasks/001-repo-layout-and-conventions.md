# 001 — Repo layout & conventions

**Phase:** 0 — Foundation
**Status:** ✅ Done (initial pass)
**Depends on:** —

## Goal

Define the repository layout and coding conventions so every later task slots into a consistent, maintainable structure.

## Decisions to confirm

- Bash version floor: **bash 4+** (associative arrays needed).
- Shell style: `set -euo pipefail`, `trap` for cleanup, `shellcheck`-clean.
- Entrypoint: a single `booooot` script that sources modules from `lib/` and `services/`.
- Module convention: one file = one responsibility; services live under `services/<name>/`.

## Proposed layout

```
booooot/                  # main entrypoint
lib/
  colors.sh               # ANSI colour helpers
  output.sh               # print/log/status helpers
  errors.sh               # error codes + die()
  args.sh                 # flag parsing
  wizard.sh               # TUI helpers (whiptail)
  state.sh                # manifest read/write
  utils.sh                # misc: platform detection, prompts, confirm
services/
  <name>/
    meta.sh               # catalog metadata (name, versions, options)
    install.sh            # direct (apt) strategy
    docker.sh             # docker strategy
    config.sh             # post-install configuration
profiles/                 # presets (lamp, lemp, dev-box) — later
tests/                    # bats suite (Phase 5)
docs/                     # generated docs, errors.md
```

## Acceptance criteria

- [ ] Layout documented in README.
- [ ] `booooot` entrypoint stub runs and prints the ghost (after 002).
- [ ] Shellcheck passes on everything committed.

## Notes

- Model the module/service split on EasyEngine (`ee`) and Convoy's structure.
- Keep everything pure bash + coreutils; no non-standard deps for flag mode.
