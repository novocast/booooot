#!/usr/bin/env bash
# art.sh — the booooot ghost and banner, rendered side by side.
# The ghost uses a placeholder scheme: special characters in the source art
# are swapped for real glyphs + colours at render time, so one glyph (e.g. █)
# can appear in several shades and outline strokes can be recoloured.

# art::ghost_lines — fills GHOST_LINES[] with the coloured ghost sprite.
# Placeholder legend (source char → rendered glyph + colour):
#   █ → █  C_GHOST         (body, main)        ▓ → █  C_GHOST_LIGHT (body, light)
#   ░ → █  C_GHOST_SHADE   (body, shade)       ▄ → ▄  C_GHOST_LIGHT (top edge)
#   . → ▄  C_GHOST         (top edge, main)    ▀ → ▀  C_GHOST_SHADE (eyes)
#   ? → /  C_GHOST         (slash, main)       - — / \ | ' → same   C_GHOST_OUTLINE
#   (space) → transparent
art::ghost_lines() {
  local art=(
    "               "
    "    -▄▓██.▄-   "
    "   /▓██████▓|  "
    "  |▓██ ▓█ ▓█▓| "
    "  |▓████████▓| "
    " |░▓████████▓| "
    " ?▓█▀░▓██▀█▓|  "
    "'——'  \▀—'\/'  "
  )
  GHOST_LINES=()
  local line i ch glyph color rendered
  for line in "${art[@]}"; do
    rendered=""
    for ((i = 0; i < ${#line}; i++)); do
      ch="${line:i:1}"
      case "$ch" in
        "█") glyph="█"; color="$C_GHOST" ;;
        "▓") glyph="█"; color="$C_GHOST_LIGHT" ;;
        "░") glyph="█"; color="$C_GHOST_SHADE" ;;
        "▄") glyph="▄"; color="$C_GHOST_LIGHT" ;;
        ".") glyph="▄"; color="$C_GHOST" ;;
        "▀") glyph="▀"; color="$C_GHOST_SHADE" ;;
        "?") glyph="/"; color="$C_GHOST" ;;
        "-" | "—" | "/" | "\\" | "|" | "'") glyph="$ch"; color="$C_GHOST_OUTLINE" ;;
        *)   glyph="$ch"; color="" ;;
      esac
      if [[ -n "$color" ]]; then
        rendered+="${color}${glyph}${C_RESET}"
      else
        rendered+="$glyph"
      fi
    done
    GHOST_LINES+=("$rendered")
  done
}

# art::banner_lines — fills BANNER_LINES[] with the extruded 3D "booooot"
# lettering, painted with a horizontal fade: characters left of the centre
# column keep the full banner blue (C_BANNER, #00FFFF), then from the centre
# column rightward the colour slowly trends toward pure black (#000000), so
# on dark terminals the right edge reads as "fading to transparent".
# Terminals have no true alpha, so the fade is an RGB interpolation toward
# black using the BANNER_FADE_FROM/TO endpoints from colors.sh. The fade is
# computed over the visible glyphs only (trailing spaces are trimmed) so the
# last visible character lands exactly on the endpoint colour. The art is
# full of backslashes, so it's stored in single-quoted strings to keep them
# literal.
art::banner_lines() {
  local art=(
    '                                                                         '
    ' ________  ________  ________  ________  ________  ________  _________   '
    '|\   __  \|\   __  \|\   __  \|\   __  \|\   __  \|\   __  \|\___   ___\ '
    '\ \  \|\ /\ \  \|\  \ \  \|\  \ \  \|\  \ \  \|\  \ \  \|\  \|___ \  \_| '
    ' \ \   __  \ \  \\\  \ \  \\\  \ \  \\\  \ \  \\\  \ \  \\\  \   \ \  \  '
    '  \ \  \|\  \ \  \\\  \ \  \\\  \ \  \\\  \ \  \\\  \ \  \\\  \   \ \  \ '
    '   \ \_______\ \_______\ \_______\ \_______\ \_______\ \_______\   \ \__\'
    '    \|_______|\|_______|\|_______|\|_______|\|_______|\|_______|    \|__|'
  )
  BANNER_LINES=()
  local line i ch width left right centre span t_num \
        leading trailing from_r from_g from_b to_r to_g to_b r g b rendered
  read -r from_r from_g from_b <<< "$BANNER_FADE_FROM"
  read -r to_r to_g to_b <<< "$BANNER_FADE_TO"
  for line in "${art[@]}"; do
    width="${#line}"
    # Trim to the visible glyph span so the fade completes exactly at the
    # last visible character; trailing spaces would otherwise dilute the
    # gradient and leave the final glyph lighter than the endpoint colour.
    # (Parameter expansion, not (( left++ )) loops — those return exit
    # status 1 and trip `set -e`.)
    leading="${line%%[! ]*}"          # leading spaces ("" if line starts with a glyph)
    trailing="${line##*[! ]}"         # trailing spaces ("" if line ends with a glyph)
    left="${#leading}"
    right=$(( ${#line} - ${#trailing} - 1 ))
    centre=$(( left + (right - left) / 2 ))
    span=$(( right - centre ))
    rendered=""
    for ((i = 0; i < width; i++)); do
      ch="${line:i:1}"
      if [[ "$ch" == " " ]]; then
        rendered+=" "
        continue
      fi
      if [[ "$BOOT_COLOR_ENABLED" != "1" ]]; then
        rendered+="$ch"
        continue
      fi
      if (( i < centre || span == 0 )); then
        rendered+="${C_BANNER}${ch}"
      else
        t_num=$(( i - centre ))
        r=$(( from_r + (to_r - from_r) * t_num / span ))
        g=$(( from_g + (to_g - from_g) * t_num / span ))
        b=$(( from_b + (to_b - from_b) * t_num / span ))
        rendered+=$'\033[38;2;'"${r};${g};${b}m${ch}"
      fi
    done
    rendered+="$C_RESET"
    BANNER_LINES+=("$rendered")
  done
}

# art::header — ghost + banner side by side, then tagline (used by help/version/about).
art::header() {
  art::ghost_lines
  art::banner_lines
  local i n="${#GHOST_LINES[@]}"
  for ((i = 0; i < n; i++)); do
    printf "%s   %s\n" "${GHOST_LINES[$i]}" "${BANNER_LINES[$i]:-}"
  done
  printf "\n  %s                   booooot — the friendly server provisioner — keeping things less scary.%s\n\n" "$C_MUTED" "$C_RESET"
}
