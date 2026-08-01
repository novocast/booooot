![booooot hero](hero.png)

# booooot
> The friendly server provisioner - Keeping things less scary.

<div align="center">

[![bash 4+](https://img.shields.io/badge/bash-4%2B-00ffff?style=flat-square&logo=gnubash&logoColor=ffffff&labelColor=1b1f23)](README.md)
[![Debian / Ubuntu](https://img.shields.io/badge/Debian%20%2F%20Ubuntu-a9fa9d?style=flat-square&labelColor=1b1f23)](documentation/tasks/README.md)
[![status: in development](https://img.shields.io/badge/status-in%20development-caa3e2?style=flat-square&labelColor=1b1f23)](documentation/tasks/)
[![dry-run safe](https://img.shields.io/badge/dry--run-safe-7cc66d?style=flat-square&labelColor=1b1f23)](documentation/GOAL.md)

</div>

**booooot** (that's *five* o's) is a command-line wizard for quickly provisioning and installing software on **Debian/Ubuntu** servers. It's built for folks who want a working stack up and running - without wading through docs, package repos, and config files.

booooot asks you what you want in plain language, then does the rest: it can install straight onto the host ("the tin") or into Docker (and later a VM), keeps track of what's installed, shows a colour-coded status dashboard, and knows the common gotchas so you don't have to.

## Table of contents

- [What it will do](#what-it-will-do)
- [How it fits together](#how-it-fits-together)
- [The splash screen](#the-splash-screen)
- [Status & roadmap](#status--roadmap)
- [Implemented so far](#implemented-so-far)
- [Command quick reference](#command-quick-reference)
- [Planned usage preview](#planned-usage-preview)
- [Testing](#testing)
- [Target requirements](#target-requirements)
- [Repository layout](#repository-layout)

## What it will do

- **Wizard + CLI** - an interactive TUI wizard for the curious, and fast flag-driven commands (`booooot install php --version 8.3 --target docker`) for the scripted.
- **Service catalog** - PHP (multiple versions), MySQL, PostgreSQL, nginx, Node.js + pnpm, Elasticsearch, Varnish.
- **Multiple install targets** - direct to host ("tin"), Docker, and VM (later).
- **Sane defaults, useful configs** - the configuration choices that matter are asked up-front; everything else has a sensible default.
- **Status dashboard** - `booooot status` shows what's installed and running, colour-coded red / amber / green for at-a-glance comprehension.
- **Idempotent** - safe to re-run, never breaks what's already there.
- **Self-diagnosing** - clear error codes, documented fixes, and a `booooot doctor` for common issues.
- **A test platform** - local VM/container + CI so booooot can be tested before it touches a real server.

## How it fits together

```mermaid
flowchart LR
    W["wizard (TUI)"] --> F["flow / validation"]
    C["flags / CLI"] --> F
    F --> P["plan (dry-run)"]
    P --> T["direct - the tin"]
    P --> D["docker"]
    P -. "later" .-> V["vm"]
    S["state manifest"] --> ST["status dashboard"]
```

## The splash screen

Every run greets you with the ghost and the extruded "booooot" banner, hand-drawn and rendered by `lib/art.sh`:

<details>
<summary><b>Tap to see the banner</b> (plain text - colourised on a real terminal)</summary>

```text
    -▄▓██.▄-
   /▓██████▓|
  |▓██ ▓█ ▓█▓|
  |▓████████▓|
 |░▓████████▓|
 ?▓█▀░▓██▀█▓|
'——'  \▀—'\/'

 ________  ________  ________  ________  ________  ________  _________
|\   __  \|\   __  \|\   __  \|\   __  \|\   __  \|\   __  \|\___   ___\
\ \  \|\ /\ \  \|\  \ \  \|\  \ \  \|\  \ \  \|\  \ \  \|\  \|___ \  \_|
 \ \   __  \ \  \\\  \ \  \\\  \ \  \\\  \ \  \\\  \ \  \\\  \   \ \  \
  \ \  \|\  \ \  \\\  \ \  \\\  \ \  \\\  \ \  \\\  \ \  \\\  \   \ \  \
   \ \_______\ \_______\ \_______\ \_______\ \_______\ \_______\   \ \__\
    \|_______|\|_______|\|_______|\|_______|\|_______|\|_______|    \|__|
```

</details>

## Status & roadmap

**In development - interface + install engine.** The wizard, flag-driven CLI, service catalog, dry-run install/uninstall flows, the colour-coded status dashboard, and the doctor health-check are implemented. The Phase 2 install engine is underway: plans now execute for real through the direct (apt) target — idempotent, with clear step output and `--dry-run` previews — with docker/vm behind the same step shape as stubs. `doctor --fix` is a dry-run stub until the fixes library lands (task 024).

| Phase | Focus | Status |
|-------|-------|--------|
| 0 - Foundation | repo layout, branding, output/error framework | done |
| 1 - Interface | CLI + TUI wizard + catalog + dry-run flows | done |
| 2 - Install engine | target abstraction, apt installers, docker, config templates | in progress |
| 3 - Services | the 7 service modules | planned |
| 4 - Reliability | error docs, idempotency & state manifest, common fixes | planned |
| 5 - Testing platform | bats suite, test VM, CI pipeline | planned |

Details live in [`documentation/GOAL.md`](documentation/GOAL.md) and the task list in [`documentation/tasks/`](documentation/tasks/).

## Implemented so far

- [x] Repo layout & conventions (`001`)
- [x] Branding, ASCII art & colours - `lib/art.sh`, `lib/colors.sh` (`002`)
- [x] Output, logging & error framework - `lib/output.sh`, `lib/errors.sh` (`003`)
- [x] CLI entrypoint & flag parsing (`004`)
- [x] Interactive TUI wizard - whiptail/dialog, back-navigation, ESC quits (`005`)
- [x] Service catalog metadata - `services/` (`006`)
- [x] Install / uninstall dry-run planning - `--plan-file` (`007`)
- [x] Status view & state dashboard - `~/.booooot/state.json` / `--state-file` (`008`)
- [x] Doctor command & health checks - `lib/doctor.sh` (`009`)
- [x] Install engine - target abstraction, consistent step output, `--dry-run`, manifest writes - `lib/engine.sh` (`011`)
- [x] Direct apt installers - idempotent apt, repos/PPAs with rollback, package resolution - `lib/apt.sh`, `lib/direct.sh` (`012`)
- [ ] Help & about screens (`010`)

## Command quick reference

| Command | What it does |
|---------|--------------|
| `booooot` / `booooot wizard` | interactive setup wizard (whiptail TUI, Linux) |
| `booooot install <svc> [options]` | install a service (apt / docker); `--dry-run` to preview |
| `booooot uninstall <svc> [options]` | remove a service (apt / docker); `--dry-run` to preview |
| `booooot status` | colour-coded state dashboard |
| `booooot list` | show the service catalog |
| `booooot doctor` | diagnose & fix common issues |
| `booooot help [command]` | per-command help |
| `booooot version` | show version and the ghost |

Global options: `--no-color`, `--log-level`, `--dry-run`, `--yes/-y`, `--no-input`, `--state-file`.

## Planned usage preview

```bash
booooot                    # launch the wizard (same as 'booooot wizard')
booooot list               # what's in the catalog
booooot install php --version 8.3 --target docker --dry-run
booooot status             # colour-coded state dashboard
booooot status --state-file ./dev-state.json   # with a dev/fake manifest
booooot doctor             # diagnose & fix common issues
booooot help install       # per-command help
```

## Testing

booooot is built to be poked at freely. Live installs only ever touch a real
Debian/Ubuntu host — everywhere else, and with `--dry-run`, nothing is changed.

**Dry-run everywhere.** `install` and `uninstall` accept `--dry-run`: they print
the exact same step-by-step output as a live run, but with "would …" details,
no side effects, and **no manifest write**. The whole install engine is
dry-run-aware, so you can preview any service, version or target safely:

```bash
booooot install php --version 8.3 --target direct --dry-run
booooot install elasticsearch --version 8.15 --target direct --dry-run
booooot install node --version 22 --target docker --dry-run
booooot uninstall mysql --dry-run
```

**Isolate state, logs and stamps.** By default booooot keeps its manifest and
logs under `~/.booooot/`. Point `BOOOOOT_HOME` (or `--state-file` /
`--log-level`) at a throwaway directory so testing never touches your real
setup:

```bash
export BOOOOOT_HOME=/tmp/booooot-test
booooot status                              # fresh home → "nothing installed yet"
booooot install php --dry-run --log-level debug   # logs land in $BOOOOOT_HOME/logs/
```

**Fake manifests.** `status`, `doctor`, idempotency and uninstall-planning can
be exercised against a hand-written manifest — no install required:

```bash
printf '%s\n' \
  '{"version":1,"services":{"mysql":{"installed":true,"version":"8.0","target":"direct","running":true}}}' \
  > /tmp/booooot-test/state.json
booooot --state-file /tmp/booooot-test/state.json status
booooot --state-file /tmp/booooot-test/state.json uninstall mysql --dry-run
booooot --state-file /tmp/booooot-test/state.json install mysql --version 8.0 --dry-run   # "already installed"
```

**Read-only commands.** `status`, `list`, `doctor`, `help`, `version` and
`--plan-file` never modify the host. `doctor --fix` is still a dry-run stub.

**Not on Debian/Ubuntu?** On other platforms (e.g. git bash on Windows, macOS)
dry-run works fully, and a live install fails fast with a clear `BOOT-` code
(such as `BOOT-1006` when there is no `sudo`) — nothing is attempted.

**Only run live installs where it's safe.** A real `booooot install` (without
`--dry-run`) actually installs packages, adds repos/PPAs, writes config and
starts services. Run it on a Debian/Ubuntu machine you're happy to change — or
in a throwaway VM/container. The automated test suite (tasks 025-027) exists
precisely so this is exercised safely.

## Target requirements

- Debian / Ubuntu (apt-based)
- bash 4+
- `whiptail` for the interactive TUI wizard (Linux environments)
- Non-interactive / flag mode: pure bash, no extra dependencies - runs in git bash on Windows

## Repository layout

```
booooot/                 # main entrypoint - wizard + flag-driven CLI
├── README.md
├── hero.png             # the booooot ghost (banner/hero art)
├── lib/                 # core modules: colors, output, errors, args, wizard, flow, plan, …
├── services/            # service catalog metadata (php, mysql, nginx, …)
└── documentation/
    ├── GOAL.md          # overarching goal, scope & principles
    └── tasks/           # one file per task, phase by phase
```

Code lands here phase by phase as the plan is completed.

---

<p align="center">
  <sub><b>booooot</b> - five o's, zero fuss · <a href="documentation/GOAL.md">the plan</a> · <a href="documentation/tasks/">task list</a></sub>
</p>
