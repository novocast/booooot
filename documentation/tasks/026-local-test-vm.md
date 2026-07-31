# 026 — Local test VM

**Phase:** 5 — Testing platform
**Status:** 📋 Not started
**Depends on:** 001 (layout), later: engine/services

## Goal

A repeatable local test environment for the user (on Windows): a clean Ubuntu VM where booooot can be exercised for real — wizard (whiptail available), direct installs, docker target, and the VM target itself.

## Approach (draft)

- **Vagrant + VirtualBox** (or Hyper-V) with an Ubuntu 24.04 box.
- Provisioner runs a smoke script: install booooot, `booooot doctor`, dry-run, then real installs on demand.
- A second, **systemd-enabled Docker container** variant (`jrei/systemd-ubuntu` style) for quick throwaway tests without a full VM.
- A snapshot/"reset to clean" workflow so the VM is always a fresh box.

## Acceptance criteria

- [ ] `vagrant up` from the repo gives a working Ubuntu box with booooot ready.
- [ ] Wizard runs interactively there (whiptail present); flag mode runs everywhere.
- [ ] Docker target testable on the VM (docker installed by the box).
- [ ] Reset path documented (destroy/recreate, or snapshot).

## Notes

- This VM doubles as the place the **VM install target** (011) gets built and tested.
- Scripted from `tests/vm/`; the smoke script can run in CI too (see 027).
