# 004 — CLI entrypoint & flag parsing

**Phase:** 1 — Interface *(current focus)*
**Status:** ✅ Done
**Depends on:** 001, 003

## Goal

The `booooot` command: subcommand dispatch plus robust flag parsing, in pure bash (works in git bash on Windows, no extra deps). This is the scriptable, LLM-testable surface.

## Command surface (planned)

```bash
booooot                        # alias for: booooot wizard
booooot wizard                 # interactive TUI wizard (needs Linux + whiptail)
booooot install <service>      # install a service
booooot uninstall <service>    # remove a service
booooot status                 # colour-coded state dashboard (008)
booooot doctor                 # diagnose & fix (009)
booooot list                   # catalog contents (006)
booooot help [command]         # help
booooot version                # version + ghost
```

## Flags (global)

`--dry-run`, `--yes` / `-y` (assume yes), `--no-input` (fail if interactive input required), `--log-level`, `--no-color`, `--state-file <path>` (for testing), `--help`, `--version`.

## Flags (per command, e.g. install)

`--target direct|docker|vm`, `--version <x.y>`, `--config <key=value>` (repeatable), `--profile <name>` (later).

## Acceptance criteria

- [x] `booooot install php --version 8.3 --target docker --dry-run` parses and produces a readable plan (stub output for now).
- [x] Unknown commands/flags fail with a `BOOT-` code and a hint.
- [x] `--no-input` + `--yes` behave correctly (no hangs).
- [x] Runs cleanly in git bash on Windows (no Linux-only calls).
- [x] `booooot help <cmd>` and `booooot --help` are correct and pretty.

## Notes

- Parsing lives in `lib/args.sh`; each subcommand registers its own flag spec.
- Prefer `getopts` or a small hand-rolled parser over external tools (portability).
- This is the first task that's directly testable by script and by LLM — add bats tests as part of 025.
