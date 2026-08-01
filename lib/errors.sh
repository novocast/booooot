#!/usr/bin/env bash
# errors.sh — BOOT error codes and the die() helper.
#
# Error code ranges:
#   0xxx generic/informational, 1xxx platform & usage, 2xxx packages/repos,
#   3xxx config, 4xxx docker, 5xxx state/manifest.

declare -A BOOT_ERRORS=(
  [BOOT-0000]="dry-run complete"
  [BOOT-0001]="not implemented yet"
  [BOOT-1001]="unsupported platform"
  [BOOT-1002]="unsupported bash version"
  [BOOT-1003]="unknown command"
  [BOOT-1004]="bad usage or unknown option"
  [BOOT-1005]="cancelled by user"
  [BOOT-1006]="required tool not found"
  [BOOT-1007]="wizard needs an interactive terminal"
  # doctor diagnostic codes (task 009) — reported by `booooot doctor`, not die()
  [BOOT-1201]="unsupported distro (doctor)"
  [BOOT-1202]="bash version too old (doctor)"
  [BOOT-1203]="required tool missing (doctor)"
  [BOOT-1204]="service marked installed but not running"
  [BOOT-1205]="no state manifest yet"
  [BOOT-1206]="config sanity check pending (Phase 2)"
  # install engine + apt (tasks 011/012)
  [BOOT-2001]="apt-get update failed"
  [BOOT-2002]="apt install/purge failed"
  [BOOT-2003]="could not add repository or PPA"
  [BOOT-2004]="could not resolve packages for a service"
  [BOOT-2005]="could not start or enable a service"
  [BOOT-3001]="config directory could not be created"
  [BOOT-4001]="docker target not implemented yet"
  [BOOT-5002]="state manifest could not be written"
  [BOOT-3002]="unknown service version"
  [BOOT-3003]="unknown config key"
  [BOOT-3004]="invalid config value"
  [BOOT-5001]="state manifest unreadable or invalid"
)

# die <code> [message...] — print a formatted error and exit 1.
die() {
  local code="${1:-BOOT-9999}"; shift || true
  local title="${BOOT_ERRORS[$code]:-unknown error}"
  out::error "BOOT error: $code — $title"
  if (( $# > 0 )); then
    printf "  "
    color::paint "$C_ERROR" "$*"
    printf "\n"
  fi
  out::_logfile error "$code $*"
  printf "  %bsee docs/errors.md#%s (error docs land in task 022)%b\n" "$C_MUTED" "$code" "$C_RESET"
  exit 1
}
