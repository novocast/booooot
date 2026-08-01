# 👻 booooot — Overarching Goal

## Mission

Make provisioning a Debian/Ubuntu server feel like a conversation with a helpful (and slightly spooky) assistant. **booooot** removes the nitty gritty of installing and configuring common server software, so a developer can go from bare box to working stack in minutes, with confidence — and with a bit of personality along the way.

## Who it's for

- Developers who want a working environment without the setup ceremony.
- Folks who don't want the nitty gritty — but still want the good stuff: multiple PHP versions, sane defaults, proper configs.
- The author, first and foremost. It's a tool to make *your* servers easy.

## Scope — in

- **Debian / Ubuntu (apt-based) servers only.**
- The seven core services: **PHP** (multiple versions), **MySQL**, **PostgreSQL**, **nginx**, **Node.js + pnpm**, **Elasticsearch**, **Varnish**.
- Three install targets: **direct to host ("tin")**, **Docker**, **VM** (later).
- **Interactive TUI wizard** (whiptail/dialog) + a fully **scriptable flag mode** (`--dry-run`, non-interactive).
- **Idempotent** installs and a live **status/state view** (red / amber / green).
- **Rich error reporting** with documented fixes, and a **doctor** command for common issues.
- A repeatable **test platform** (container/VM) plus CI.

## Scope — out

- Non-Debian distros (RHEL, Arch, etc.) — explicitly **not** supported.
- Remote orchestration of fleets at scale — this is a single-box helper, not Ansible.
- Windows/macOS as install *targets* (dev on Windows; test via VM/WSL/CI).

## Guiding principles

1. **No nitty gritty.** Defaults are sane; the choices asked are in plain language.
2. **Re-runnable.** Never leave a half-broken system; safe to run again.
3. **Transparent.** Every step is visible, logged, and explainable.
4. **Self-diagnosing.** Errors carry codes (`BOOT-xxxx`) that link to documented causes and fixes.
5. **Testable by machine.** Flags, `--dry-run`, and non-interactive modes make booooot automatable and LLM-testable.
6. **Charming.** Colour, ASCII art, a ghost — the personality is a feature, not a bug.

## Success criteria (eventual)

- A fresh Ubuntu box goes from zero to a working LEMP + MySQL + Node.js stack via the wizard in minutes.
- `booooot status` gives a trustworthy, colour-coded at-a-glance view.
- Every documented error has a working fix path; `booooot doctor` resolves the common ones.
- The test platform (VM + CI) exercises the tool end-to-end before it touches a real server.

## Current phase

**Phase 2 — install engine.** The interface (wizard + CLI + catalog + dry-run flows) is done and safe. Plans now execute for real through the direct (tin/apt) target — idempotent, step-by-step output, `--dry-run` previews — with docker and vm targets behind the same step shape (stubs for tasks 013/026). Every step is visible and logged; the state manifest is only written after success. See [`tasks/`](tasks/).
