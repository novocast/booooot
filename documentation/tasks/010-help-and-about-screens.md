# 010 — Help & about screens

**Phase:** 1 — Interface *(current focus)*
**Status:** 📋 Not started
**Depends on:** 002, 004

## Goal

Friendly, complete help: `booooot help`, `booooot help <command>`, `booooot version`, and an about screen featuring the ghost. The "first impression" surface.

## Deliverables

- `booooot help` — overview of commands + global flags, ghost header.
- `booooot help <command>` — usage, flags, examples for that command (from its registered spec in 004).
- `booooot version` — version number, bash version, ghost + banner.
- `--help` on any command behaves like `help <command>`.

## Acceptance criteria

- [ ] Every command has a help entry; nothing shows a raw parse error when `--help` is passed.
- [ ] Help renders correctly on 80-col terminals and in git bash.
- [ ] Examples are copy-pasteable and reflect real (if future) behaviour.

## Notes

- Keep examples aligned with the planned usage in the README.
