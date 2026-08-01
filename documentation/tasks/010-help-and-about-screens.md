# 010 — Help & about screens

**Phase:** 1 — Interface *(current focus)*
**Status:** ✅ Done
**Depends on:** 002, 004

## Goal

Friendly, complete help: `booooot help`, `booooot help <command>`, `booooot version`, and an about screen featuring the ghost. The "first impression" surface.

## Deliverables

- `booooot help` — overview of commands + global flags, ghost header.
- `booooot help <command>` — usage, flags, examples for that command (from its registered spec in 004).
- `booooot version` — version number, bash version, ghost + banner.
- `--help` on any command behaves like `help <command>`.

## Acceptance criteria

- [x] Every command has a help entry; nothing shows a raw parse error when `--help` is passed.
- [x] Help renders correctly on 80-col terminals and in git bash.
- [x] Examples are copy-pasteable and reflect real (if future) behaviour.

## Notes

- Keep examples aligned with the planned usage in the README.

## Implemented

- **`booooot help`** — the overview screen: ghost + banner header, every command with a one-line description, global options, and copy-pasteable examples. `booooot` with no arguments and `booooot --help` show the same overview.
- **`booooot help <command>`** — a help topic for every command — `wizard`, `install`, `uninstall`, `status`, `doctor`, `list`, plus `help` and `version` — each with usage, flags and examples. An unknown topic fails with `BOOT-1004` and lists the valid topics.
- **`booooot version`** — the about screen featuring the ghost: ghost + banner, the booooot version number, the running bash version, the detected platform (plus its pretty name when `/etc/os-release` is readable) and a friendly footer. `booooot --version` / `booooot -V` behave the same.
- **`--help` everywhere** — every command accepts `--help` (and `-h`), routed to `cmd_help <command>`; `version --help` and `help --help` work too, so nothing ever shows a raw parse error when `--help` is passed. Global flags like `--no-color` are accepted after `help` as well.
- **80-col friendly** — all help text lines are ≤ 78 columns (only the shared branding banner, present on every screen, is wider).
- Wired in the entrypoint: a `VERSION_BOOLS` / `VERSION_VALUES` flag spec, `version` added to the per-command parse switch, the new `cmd_help` topics, an expanded `cmd_version`, and removal of the now-unused `cmd_stub`.
