# 005 — Interactive TUI wizard framework

**Phase:** 1 — Interface *(current focus)*
**Status:** ✅ Done
**Depends on:** 001, 003, 006

## Goal

A consistent interactive wizard built on **whiptail** (dialog as an alternative backend): menus, checklists, radiolists, input boxes, and a shared layout with the ghost branding.

## Design decisions (confirmed)

- **whiptail/dialog TUI** is the wizard engine.
- The TUI requires a **Linux environment** (whiptail is not in git bash). The wizard is tested there — via the test VM (026), WSL, or CI — while flag mode (004) remains the git-bash-testable path.
- Keep every screen *driven by catalog metadata* (006) so menus stay in sync automatically.

## Framework pieces

- `lib/wizard.sh`: thin wrappers (`wizard_menu`, `wizard_radio`, `wizard_checklist`, `wizard_input`, `wizard_confirm`) with a consistent title/back/cancel convention.
- Back / cancel navigation at every step; ESC or Cancel returns to the previous menu (or quits cleanly with a `BOOT-` "cancelled" note, not an error).
- A `wizard_summary` screen that shows the chosen plan before anything "happens".

## Acceptance criteria

- [x] A wizard run can reach every screen without crashing; back/cancel work everywhere.
- [x] Screens are generated from catalog data, not hard-coded lists.
- [x] `booooot wizard` in a non-TTY (or with `--no-input`) fails gracefully with a pointer to flag mode.
- [x] Layout shows the ghost/banner header.

## Notes

- **Implemented:** `lib/wizard.sh` — thin wrappers (`wizard::menu/radio/checklist/input/confirm/summary`) over whiptail with dialog as an automatic fallback; every screen maps Cancel/ESC (1/255) to "back one screen". Non-TTY / `--no-input` → `BOOT-1007` (missing backend → `BOOT-1006`), both pointing at flag mode. The ghost/banner branding rides in the whiptail `--backtitle`.
- The wizard flow itself (service → version → target → config → summary → confirm) lives in `lib/flow.sh` (task 007).
- **Future enhancement (decide later):** prompt-based fallback when whiptail is missing, so the wizard can run anywhere. Keep the wrapper layer thin so this is cheap to add.
- whiptail returns codes: 0 = OK, 1 = Cancel, 255 = ESC — handle all three.
- For LLM-driven wizard testing, prefer exercising flag mode + asserting on `--dry-run` plans; the TUI itself is best verified visually/on the VM.
