# 002 — Branding, ASCII art & colours

**Phase:** 0 — Foundation
**Status:** ✅ Done (initial pass)
**Depends on:** 001

## Goal

Give booooot its personality: a friendly ghost, big "booooot" lettering, and a consistent colour system — all defined once and reused everywhere.

## Deliverables

- A ghost ASCII mascot (draft below — refine + colour).
- A "booooot" banner (hand-drawn ANSI art; `figlet`/`toilet` optional at runtime, never required).
- Colour system in `lib/colors.sh`: theme vars (`BOOT_C_GREEN`, `BOOT_C_RED`, …), helpers to emit coloured text, and a `--no-color` / `NO_COLOR` escape hatch.
- ASCII art assets in one place (`lib/art.sh` or `assets/`).

## Draft ghost (start here)

```
     .--------.
    /          \
   |   O    O   |
   |     __     |
   |    /  \    |
    \   \  /   /
     `--'  `--'
      |      |
      |      |
     /        \
```

## Acceptance criteria

- [ ] `booooot --version` / about screen shows the ghost + banner.
- [ ] All colour output goes through the colour system; `NO_COLOR=1` disables it.
- [ ] Art renders cleanly on 80-col terminals (and in git bash).

## Notes

- White/blue palette suits a ghost; accent colour per severity (green/amber/red) reserved for status.
- Keep the ghost small enough to sit beside the banner without wrapping.
