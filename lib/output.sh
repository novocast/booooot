#!/usr/bin/env bash
# output.sh — console + file logging for booooot.

BOOT_LOG_LEVEL="${BOOT_LOG_LEVEL:-info}"

# out::_logfile <level> <message...> — append a plain line to the log file.
out::_logfile() {
  local level="$1"; shift
  if [[ -n "${BOOT_LOG_FILE:-}" ]]; then
    printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*" >> "$BOOT_LOG_FILE" 2>/dev/null || true
  fi
}

# out::_emit <color> <label> <message...> — internal printer.
out::_emit() {
  local color="$1" label="$2"; shift 2
  color::paint "$color" "$label"
  printf " %s\n" "$*"
}

out::info()  { out::_emit "$C_INFO"  "[*]" "$@"; out::_logfile info  "$*"; }
out::ok()    { out::_emit "$C_OK"    "[+]" "$@"; out::_logfile ok    "$*"; }
out::warn()  { out::_emit "$C_WARN"  "[!]" "$@"; out::_logfile warn  "$*"; }
out::error() { out::_emit "$C_ERROR" "[x]" "$@"; out::_logfile error "$*"; }

out::debug() {
  out::_logfile debug "$*"
  if [[ "$BOOT_LOG_LEVEL" == "debug" ]]; then
    out::_emit "$C_DEBUG" "[.]" "$@"
  fi
}

# out::step <current> <total> <message...> — progress step, e.g. [2/5] …
out::step() {
  out::_emit "$C_ACCENT" "[$1/$2]" "${@:3}"
  out::_logfile step "${@:3}"
}

# out::section <title> — a bold section header.
out::section() {
  printf "\n"
  color::paint "$C_BOLD" "== $* =="
  printf "\n"
}
