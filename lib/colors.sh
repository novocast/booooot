#!/usr/bin/env bash
# colors.sh — ANSI colour system for booooot.
# All coloured output goes through this module so NO_COLOR / --no-color can
# disable it globally. Uses raw ANSI escapes (no tput) for portability.

# --- base codes ---
# ANSI-C quoting ($'...') so these hold a real ESC byte, not the literal text
# "\033" — that keeps printf '%s' safe and avoids escaping headaches when
# codes sit next to literal backslashes in ASCII art.
C_RESET=$'\033[0m'
C_BOLD=$'\033[1m'
C_DIM=$'\033[2m'
C_UNDERLINE=$'\033[4m'

# --- foregrounds ---
C_BLACK=$'\033[30m'
C_RED=$'\033[31m'
C_GREEN=$'\033[32m'
C_YELLOW=$'\033[33m'
C_BLUE=$'\033[34m'
C_MAGENTA=$'\033[35m'
C_CYAN=$'\033[36m'
C_WHITE=$'\033[37m'
C_BRIGHT_BLACK=$'\033[90m'
C_BRIGHT_RED=$'\033[91m'
C_BRIGHT_GREEN=$'\033[92m'
C_BRIGHT_YELLOW=$'\033[93m'
C_BRIGHT_BLUE=$'\033[94m'
C_BRIGHT_MAGENTA=$'\033[95m'
C_BRIGHT_CYAN=$'\033[96m'
C_BRIGHT_WHITE=$'\033[97m'

# --- backgrounds ---
C_BG_BLACK=$'\033[40m'
C_BG_RED=$'\033[41m'
C_BG_GREEN=$'\033[42m'
C_BG_YELLOW=$'\033[43m'
C_BG_BLUE=$'\033[44m'
C_BG_MAGENTA=$'\033[45m'
C_BG_CYAN=$'\033[46m'
C_BG_WHITE=$'\033[47m'

# --- semantic theme (populated by color::init) ---
C_OK=""; C_WARN=""; C_ERROR=""; C_INFO=""; C_DEBUG=""
C_GHOST=""; C_GHOST_LIGHT=""; C_GHOST_SHADE=""; C_GHOST_OUTLINE=""; C_BANNER=""; C_ACCENT=""; C_MUTED=""
BOOT_COLOR_ENABLED=1

# --- banner fade endpoints (plain RGB triplets, not ANSI codes) ---
# Terminals have no alpha channel, so the banner "fades to transparent" by
# interpolating toward pure black (#000000), which reads as transparent on
# dark terminals. art::banner_lines paints C_BANNER (#00FFFF) left of the
# centre column and fades toward BANNER_FADE_TO on the right.
BANNER_FADE_FROM="0 255 255"
BANNER_FADE_TO="0 0 0"

# color::init — enable/disable colour; call once at startup (and again after
# parsing --no-color). Honours the NO_COLOR convention.
color::init() {
  if [[ -n "${NO_COLOR:-}" ]] || [[ "${BOOT_NO_COLOR:-0}" == "1" ]]; then
    BOOT_COLOR_ENABLED=0
  fi
  if [[ "$BOOT_COLOR_ENABLED" == "1" ]]; then
    C_OK="$C_BRIGHT_GREEN"
    C_WARN="$C_BRIGHT_YELLOW"
    C_ERROR="$C_BRIGHT_RED"
    C_INFO="$C_BRIGHT_CYAN"
    C_DEBUG="$C_DIM"
    C_GHOST=$'\033[38;2;169;250;157m'        # #a9fa9d
    C_GHOST_LIGHT=$'\033[38;2;124;198;109m'   # #7cc66d
    C_GHOST_SHADE=$'\033[38;2;71;119;59m'     # #47773b
    C_GHOST_OUTLINE=$'\033[38;2;202;163;226m' # #caa3e2
    C_BANNER=$'\033[38;2;0;255;255m'        # #00FFFF (bright cyan — banner blue)
    C_ACCENT="$C_BRIGHT_MAGENTA"
    C_MUTED="$C_DIM"
  else
    C_OK=""; C_WARN=""; C_ERROR=""; C_INFO=""; C_DEBUG=""
    C_GHOST=""; C_GHOST_LIGHT=""; C_GHOST_SHADE=""; C_GHOST_OUTLINE=""; C_BANNER=""; C_ACCENT=""; C_MUTED=""
    C_RESET=""
  fi
}

# color::paint <code> <text...> — print text wrapped in a colour.
color::paint() {
  local code="$1"; shift
  if [[ "$BOOT_COLOR_ENABLED" == "1" ]] && [[ -n "$code" ]]; then
    printf "%b%s%b" "$code" "$*" "$C_RESET"
  else
    printf "%s" "$*"
  fi
}
