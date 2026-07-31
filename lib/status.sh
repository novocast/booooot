#!/usr/bin/env bash
# status.sh — the colour-coded status dashboard (task 008).
#
# Renders `booooot status`: a service table (service, version, target,
# running, health) read from the state manifest (see lib/state.sh).
#   green — installed & running (healthy)
#   amber — installed but not running (or config not applied)
#   red   — expected but missing / not installed
# Colours come from the semantic theme; with --no-color the ✓ / ~ / ✗ glyphs
# carry the meaning so the dashboard stays readable.

# status::health <svc> — prints one of: green | amber | red.
status::health() {
  local svc="$1"
  if state::installed "$svc"; then
    if [[ "$(state::field "$svc" running false)" == "true" ]]; then
      printf 'green'
    else
      printf 'amber'
    fi
  else
    printf 'red'
  fi
}

# status::_glyph <health> — glyph for a health state (readable without colour).
status::_glyph() {
  case "$1" in
    green) printf '✓' ;;
    amber) printf '~' ;;
    *)     printf '✗' ;;
  esac
}

# status::_label <health> — short human label for a health state.
status::_label() {
  case "$1" in
    green) printf 'running' ;;
    amber) printf 'stopped' ;;
    *)     printf 'missing' ;;
  esac
}

# status::_color <health> — ANSI colour for a health state.
status::_color() {
  case "$1" in
    green) printf '%s' "$C_OK" ;;
    amber) printf '%s' "$C_WARN" ;;
    *)     printf '%s' "$C_ERROR" ;;
  esac
}

# status::_table_head — the column header row.
status::_table_head() {
  printf "  %-13s %-9s %-9s %-9s  %s\n" "service" "version" "target" "running" "health"
  printf "  %-13s %-9s %-9s %-9s  %s\n" "-------" "-------" "------" "-------" "------"
}

# status::_row <svc> — print one table row (values from the manifest, or '—').
status::_row() {
  local svc="$1"
  local health ver tgt run glyph label color
  health="$(status::health "$svc")"
  if state::installed "$svc"; then
    ver="$(state::field "$svc" version "$(catalog::default_version "$svc")")"
    tgt="$(state::field "$svc" target "")"; [[ -n "$tgt" ]] || tgt="-"
    if [[ "$(state::field "$svc" running false)" == "true" ]]; then run="yes"; else run="no"; fi
  else
    ver="-"; tgt="-"; run="-"
  fi
  glyph="$(status::_glyph "$health")"
  label="$(status::_label "$health")"
  color="$(status::_color "$health")"
  printf "  %-13s %-9s %-9s %-9s  " "$svc" "$ver" "$tgt" "$run"
  color::paint "$color" "$glyph $label"
  printf "\n"
}

# status::_legend — the colour/glyph key.
status::_legend() {
  local g a r
  g="$(status::_color green)"
  a="$(status::_color amber)"
  r="$(status::_color red)"
  printf "  legend: "
  color::paint "$g" "✓ green"
  printf "  installed & running    "
  color::paint "$a" "~ amber"
  printf "  installed, not running    "
  color::paint "$r" "✗ red"
  printf "  expected but missing\n"
}

# status::render <state_file> — the dashboard. Missing manifest is handled
# gracefully (all-red "nothing installed yet" view, not an error); a manifest
# that exists but can't be parsed is a real failure (BOOT-5001).
status::render() {
  local file="${1:-$BOOT_STATE_FILE}"
  art::header

  if [[ ! -f "$file" || ! -r "$file" ]]; then
    status::_empty_view "$file"
    return 0
  fi

  if ! state::load "$file"; then
    die BOOT-5001 "state manifest is not valid JSON: $file"
  fi

  out::section "Status dashboard"
  status::_table_head

  local svc green=0 amber=0 red=0
  for svc in $(catalog::services); do
    status::_row "$svc"
    case "$(status::health "$svc")" in
      green) green=$((green + 1)) ;;
      amber) amber=$((amber + 1)) ;;
      *)     red=$((red + 1)) ;;
    esac
  done

  printf "\n"
  local installed=$((green + amber))
  out::info "$installed installed · $green running · $red not installed  (state: $file)"
  status::_legend
}

# status::_empty_view <file> — all-red "nothing installed yet" dashboard.
status::_empty_view() {
  local file="$1"
  out::section "Status dashboard"
  status::_table_head
  local svc
  for svc in $(catalog::services); do
    status::_row "$svc"
  done
  printf "\n"
  out::warn "nothing installed yet — no state manifest at $file"
  out::info "plan an install: booooot install <service> --version X --target T --dry-run"
  status::_legend
}
