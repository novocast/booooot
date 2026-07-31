# 009 — Doctor command

**Phase:** 1 — Interface *(current focus)*
**Status:** 📋 Not started
**Depends on:** 003, 006, 008

## Goal

`booooot doctor` — a health check + first-aid command: detect the common problems, report them with error codes and explanations, and (in later phases) offer one-command fixes.

## Checks (interface phase = stub registry)

- Environment: distro support, bash version, required tools present.
- State consistency: manifest says installed but something's off (later phases add real probes: ports, service units, versions).
- Config sanity: template files vs expected values (later).

## Output shape (per check)

```
[🟢] BOOT-0000 distro check — Ubuntu 24.04 supported
[🔴] BOOT-1204 php not running but marked installed — try `booooot doctor --fix php`
```

## Acceptance criteria

- [ ] `booooot doctor` runs, lists checks, colour-coded, with codes.
- [ ] `--fix <service>` offered as a stub (dry-run message) in this phase.
- [ ] No real system probing beyond safe reads (interface phase stays harmless).

## Notes

- The fixes library (024) plugs in behind the `--fix` surface later.
- Doctor output is another great LLM/scripted-test surface — keep it line-stable.
