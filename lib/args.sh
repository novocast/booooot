#!/usr/bin/env bash
# args.sh — per-command flag parsing for booooot.
#
# Each subcommand declares its accepted flags (see the specs in the booooot
# entrypoint), then calls args::parse. Parsed values land in BOOT_ARGS,
# positionals in BOOT_POSARGS, repeated --config pairs in BOOT_CONFIGS.

declare -A BOOT_ARGS=()
declare -a BOOT_POSARGS=()
declare -A BOOT_CONFIGS=()
declare -A BOOT_REPEATS=()

# args::reset — clear parsed state.
args::reset() {
  BOOT_ARGS=()
  BOOT_POSARGS=()
  BOOT_CONFIGS=()
  BOOT_REPEATS=()
}

# args::parse <bools_csv> <values_csv> <repeat_csv> <args...>
#   bools_csv:   comma-separated flags that take no value (e.g. "yes,no-color")
#   values_csv:  comma-separated flags that take a value (e.g. "target,version")
#   repeat_csv:  comma-separated value flags that may repeat (e.g. "config")
# Supports --flag, --flag=value, --flag value, and -y/-h/-V short forms.
# Unknown flags fail with BOOT-1004.
args::parse() {
  local bools_csv="$1" values_csv="$2" repeat_csv="$3"; shift 3
  args::reset

  local -A bools=() values=()
  local b v r
  for b in ${bools_csv//,/ }; do bools[$b]=1; done
  for v in ${values_csv//,/ }; do values[$v]=1; done
  for r in ${repeat_csv//,/ }; do BOOT_REPEATS[$r]=1; done

  local pos=0 name val
  while (( $# > 0 )); do
    case "$1" in
      --)
        shift
        while (( $# > 0 )); do
          BOOT_POSARGS[$pos]="$1"; pos=$((pos+1)); shift
        done
        ;;
      --*=*)
        name="${1%%=*}"; val="${1#*=}"
        name="${name#--}"
        if [[ -n "${bools[$name]:-}" ]]; then
          die BOOT-1004 "flag --$name does not take a value"
        fi
        args::_store "$name" "$val"
        shift
        ;;
      --*)
        name="${1#--}"
        if [[ -n "${bools[$name]:-}" ]]; then
          BOOT_ARGS[$name]=1; shift
        elif [[ -n "${values[$name]:-}" ]]; then
          if (( $# < 2 )); then die BOOT-1004 "option --$name needs a value"; fi
          args::_store "$name" "$2"
          shift 2
        else
          die BOOT-1004 "unknown option: $1 (try 'booooot help')"
        fi
        ;;
      -y) BOOT_ARGS[yes]=1; shift ;;
      -h) BOOT_ARGS[help]=1; shift ;;
      -V) BOOT_ARGS[version]=1; shift ;;
      -*)
        die BOOT-1004 "unknown option: $1 (try 'booooot help')"
        ;;
      *)
        BOOT_POSARGS[$pos]="$1"; pos=$((pos+1)); shift
        ;;
    esac
  done
}

# args::_store <name> <value> — store a value flag; repeatable flags are
# comma-joined, and --config key=value pairs also land in BOOT_CONFIGS.
args::_store() {
  local name="$1" val="$2"
  if [[ -n "${BOOT_REPEATS[$name]:-}" ]]; then
    BOOT_ARGS[$name]="${BOOT_ARGS[$name]:-}${BOOT_ARGS[$name]:+,}$val"
    if [[ "$name" == "config" ]]; then
      BOOT_CONFIGS["${val%%=*}"]="${val#*=}"
    fi
  else
    BOOT_ARGS[$name]="$val"
  fi
}

# args::apply_globals — fold global flags found after the command into the
# BOOT_* globals (called by main after per-command parsing).
args::apply_globals() {
  [[ "${BOOT_ARGS[no-color]:-0}" == "1" ]] && { BOOT_NO_COLOR=1; color::init; }
  [[ "${BOOT_ARGS[dry-run]:-0}" == "1" ]] && BOOT_DRY_RUN=1
  [[ "${BOOT_ARGS[yes]:-0}" == "1" ]] && BOOT_YES=1
  [[ "${BOOT_ARGS[no-input]:-0}" == "1" ]] && BOOT_NO_INPUT=1
  [[ -n "${BOOT_ARGS[log-level]:-}" ]] && BOOT_LOG_LEVEL="${BOOT_ARGS[log-level]}"
  [[ -n "${BOOT_ARGS[state-file]:-}" ]] && BOOT_STATE_FILE="${BOOT_ARGS[state-file]}"
  return 0  # avoid set -e tripping on the last test's exit status
}
