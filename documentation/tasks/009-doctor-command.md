# 009 — Doctor command

**Phase:** 1 — Interface *(current focus)*
**Status:** ✅ Done
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

- [x] `booooot doctor` runs, lists checks, colour-coded, with codes.
- [x] `--fix <service>` offered as a stub (dry-run message) in this phase.
- [x] No real system probing beyond safe reads (interface phase stays harmless).

## Notes

- The fixes library (024) plugs in behind the `--fix` surface later.
- Doctor output is another great LLM/scripted-test surface — keep it line-stable.

## Implemented

- **`lib/doctor.sh`** — the check registry + report renderer. `doctor::render` runs every check in order and prints one line each in the shape `[glyph] CODE name — detail`, with glyphs `✓` / `~` / `✗` / `·` staying readable without colour. Exits 1 when any check fails, so scripts can react.
- **Checks (safe reads only)**
  - `distro` — green on Debian/Ubuntu (`BOOT-0000`); amber on anything else (`BOOT-1201`, dev/test mode).
  - `bash` — green when bash 4+ (`BOOT-0000`); red below (`BOOT-1202`).
  - `tools` — `apt-get` essential (red `BOOT-1203` when missing); `whiptail` optional (amber when missing).
  - `manifest` — no manifest → info (`BOOT-1205`); unreadable/invalid → red `BOOT-5001`; installed-but-not-running services → one red line each (`BOOT-1204`) with a `--fix` hint; all consistent → green `BOOT-0000`.
  - `config` — stub, info (`BOOT-1206`); real template-vs-expected checks land in Phase 2.
- **`--fix <service>`** — `doctor::fix` (dry-run stub): validates the service against the catalog, reports what the fix would address from the manifest, and ends with a `BOOT-0001` dry-run message until the fixes library (024) lands.
- **Codes** — doctor diagnostics recorded in `lib/errors.sh` (`BOOT-1201`…`BOOT-1206`); `platform::pretty_name` / `platform::version_id` added to `lib/utils.sh`.
- **`booooot doctor`** wired into the entrypoint: sources `lib/doctor.sh`, adds `--fix` to the doctor flag spec, replaces the stub dispatch with `cmd_doctor`, and updates `cmd_help doctor`.
