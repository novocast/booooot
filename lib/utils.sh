#!/usr/bin/env bash
# utils.sh — misc small helpers.

# platform::id — distro id from /etc/os-release, or 'unknown'.
platform::id() {
  if [[ -r /etc/os-release ]]; then
    ( . /etc/os-release; printf '%s' "${ID:-unknown}" )
  else
    printf '%s' "unknown"
  fi
}

# platform::is_debian_family — true on Debian/Ubuntu (booooot's supported OSes).
platform::is_debian_family() {
  local id
  id="$(platform::id)"
  [[ "$id" == "debian" || "$id" == "ubuntu" ]]
}

# cmd::exists — true if a command is on PATH.
cmd::exists() { command -v "$1" >/dev/null 2>&1; }

# ui::confirm <prompt> — returns 0 on yes, 1 on no.
# Honours --yes (auto-confirm) and --no-input (fail instead of prompting).
# Never hangs: EOF on stdin counts as "no".
ui::confirm() {
  local prompt="${1:-Continue?}"
  if [[ "$BOOT_YES" == "1" ]]; then return 0; fi
  if [[ "$BOOT_NO_INPUT" == "1" ]]; then
    die BOOT-1005 "$prompt (pass --yes to confirm non-interactively)"
  fi
  local reply=""
  color::paint "$C_INFO" "[?]"
  printf " %s [y/N] " "$prompt"
  read -r reply || reply=""
  printf "\n"
  [[ "$reply" == "y" || "$reply" == "Y" || "$reply" == "yes" || "$reply" == "Yes" || "$reply" == "YES" ]]
}

# service::known <name> — true if name is one of the catalog services.
# Thin wrapper over the catalog (task 006); kept for compatibility.
service::known() { catalog::is_service "$1"; }

# str::truncate <text> <maxlen> — truncate with an ellipsis if needed.
str::truncate() {
  local text="$1" max="$2"
  if (( ${#text} > max )); then
    printf '%s…' "${text:0:max-1}"
  else
    printf '%s' "$text"
  fi
}
