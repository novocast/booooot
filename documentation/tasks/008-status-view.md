# 008 — Status view (state + dashboard)

**Phase:** 1 — Interface *(current focus)*
**Status:** ✅ Done
**Depends on:** 003, 006

## Goal

`booooot status` — a colour-coded dashboard of what's installed, what version, and whether it's running, read from a **state manifest**. Red / green / amber for at-a-glance comprehension.

## State manifest (draft)

- Location: `~/.booooot/state.json` by default; overridable with `--state-file` (so the interface phase can test with a fake/dev state file in git bash).
- Shape (JSON):
  ```json
  {
    "version": 1,
    "services": {
      "php": { "installed": true, "version": "8.3", "target": "docker", "running": true, "updated_at": "…" },
      "mysql": { "installed": false }
    }
  }
  ```

## Colour coding

- 🟢 green — installed and running / healthy
- 🟡 amber — installed but not running, or config not applied
- 🔴 red — expected but missing / failed state

## Acceptance criteria

- [x] `booooot status` renders a service table (service, version, target, running, health colour).
- [x] Reads real manifest if present; in this phase a dev state file (`--state-file ./dev-state.json`) is the test path.
- [x] Unknown/missing manifest is handled gracefully (all-red "nothing installed yet" view, not an error).
- [x] Colour legend printed; `--no-color` still readable (e.g. ✓/~ /✗ glyphs).

## Notes

- Manifest semantics (how states transition, idempotency) are formalised in **023**; this task only builds the read/render side.
- `lib/state.sh` will be the single writer later — all installs report into it.

## Implemented

- **`lib/state.sh`** — the manifest reader: pure-bash tolerant JSON parse (no jq) of `~/.booooot/state.json` into `STATE_SERVICES[]` + `STATE_FIELDS["svc.field"]`. `state::load` returns 0 loaded / 1 missing-unreadable / 2 malformed; `state::field` and `state::installed` are the accessors the dashboard (and later the engine/doctor) use.
- **`lib/status.sh`** — the dashboard renderer: `status::render <state-file>` draws the ghost banner, the service table (service, version, target, running, health) in catalog order, a summary line, and the colour legend. Health: green = installed & running, amber = installed but not running, red = expected but missing. A missing manifest renders an all-red "nothing installed yet" view (exit 0); a present-but-invalid manifest fails with **BOOT-5001**.
- **`booooot status`** wired into the entrypoint (sources + `cmd_status`); `--state-file` honoured via the existing global-flag path.
- **`dev-state.json`** (gitignored) — sample manifest covering green (php, node), amber (mysql) and red (nginx + absent services) for quick `./booooot status --state-file ./dev-state.json` testing.
