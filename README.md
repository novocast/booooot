# @file:hero.png

> The friendly server provisioner - Keeping things less scary.

**booooot** (that's *five* o's) is a command-line wizard for quickly provisioning and installing software on **Debian/Ubuntu** servers. It's built for folks who want a working stack up and running — without wading through docs, package repos, and config files.

booooot asks you what you want in plain language, then does the rest: it can install straight onto the host ("the tin") or into Docker (and later a VM), keeps track of what's installed, shows a colour-coded status dashboard, and knows the common gotchas so you don't have to.

## What it will do

- **Wizard + CLI** — an interactive TUI wizard for the curious, and fast flag-driven commands (`booooot install php --version 8.3 --target docker`) for the scripted.
- **Service catalog** — PHP (multiple versions), MySQL, PostgreSQL, nginx, Node.js + pnpm, Elasticsearch, Varnish.
- **Multiple install targets** — direct to host ("tin"), Docker, and VM (later).
- **Sane defaults, useful configs** — the configuration choices that matter are asked up-front; everything else has a sensible default.
- **Status dashboard** — `booooot status` shows what's installed and running, colour-coded red / amber / green for at-a-glance comprehension.
- **Idempotent** — safe to re-run, never breaks what's already there.
- **Self-diagnosing** — clear error codes, documented fixes, and a `booooot doctor` for common issues.
- **A test platform** — local VM/container + CI so booooot can be tested before it touches a real server.

## Status

🚧 **In development — interface layer done.** The wizard, flag-driven CLI, service catalog, dry-run install/uninstall flows, and the colour-coded status dashboard are implemented and safe to run: nothing touches a real system yet. `doctor` is a stub coming in the next task. Details live in [`documentation/GOAL.md`](documentation/GOAL.md) and the task list in [`documentation/tasks/`](documentation/tasks/).

## Implemented so far

- **`booooot wizard`** — interactive TUI (whiptail/dialog) with back-navigation at every step; ESC anywhere quits cleanly.
- **`booooot install <svc> …` / `booooot uninstall <svc> …`** — flag-driven planning, validated against the catalog, **dry-run only** (nothing is changed).
- **`booooot list`** — the service catalog: php, mysql, postgresql, nginx, node, elasticsearch, varnish.
- **`booooot status`** — colour-coded state dashboard (green / amber / red) read from the state manifest (`~/.booooot/state.json`, or `--state-file`).
- **`--plan-file <path>`** — dumps a plain-text plan for scripting and test assertions.

## Target requirements

- Debian / Ubuntu (apt-based)
- bash 4+
- `whiptail` for the interactive TUI wizard (Linux environments)
- Non-interactive / flag mode: pure bash, no extra dependencies — runs in git bash on Windows

## Planned usage preview

```bash
booooot                    # launch the wizard (same as 'booooot wizard')
booooot list               # what's in the catalog
booooot install php --version 8.3 --target docker --dry-run
booooot status             # colour-coded state dashboard
booooot status --state-file ./dev-state.json   # with a dev/fake manifest
booooot doctor             # diagnose & fix common issues (coming soon)
booooot help install       # per-command help
```

## Repository layout

```
booooot/                 # main entrypoint — wizard + flag-driven CLI
├── README.md
├── hero.png             # the booooot ghost (banner/hero art)
├── lib/                 # core modules: colors, output, errors, args, wizard, flow, plan, …
├── services/            # service catalog metadata (php, mysql, nginx, …)
└── documentation/
    ├── GOAL.md          # overarching goal, scope & principles
    └── tasks/           # one file per task, phase by phase
```

Code lands here phase by phase as the plan is completed.
