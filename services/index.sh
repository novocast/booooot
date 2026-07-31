#!/usr/bin/env bash
# services/index.sh — the service catalog (task 006).
#
# Single source of truth for every service booooot can manage. The wizard
# menus (lib/wizard.sh + lib/flow.sh), `booooot list`, and the --version /
# --config validation in the CLI all read from here — nothing is hard-coded
# elsewhere. This file only *describes* services; installs land in Phase 2.

BOOT_ROOT="${BOOT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Display order for menus and `booooot list`.
BOOT_SERVICE_ORDER=(php mysql postgresql nginx node elasticsearch varnish)

# Flat metadata: BOOT_CATALOG["<svc>.<field>"] = value.
#   fields: name, label, description, versions, default_version, targets, configs
declare -A BOOT_CATALOG=()

# Config-option specs: BOOT_CATALOG_CFG["<svc>.<key>"] = "label|type|default|choices"
#   type:    select | bool | string | int | checklist
#   choices: comma-separated (used by select/checklist)
declare -A BOOT_CATALOG_CFG=()

# catalog::load — register every service (call once at startup).
catalog::load() {
  local s
  for s in "${BOOT_SERVICE_ORDER[@]}"; do
    "catalog_${s}::register"
  done
}

# --- getters ----------------------------------------------------------------

catalog::services() { printf '%s\n' "${BOOT_SERVICE_ORDER[@]}"; }
catalog::services_csv() {
  local csv="" s
  for s in "${BOOT_SERVICE_ORDER[@]}"; do csv+="${csv:+,}$s"; done
  printf '%s' "$csv"
}
catalog::get()                { printf '%s' "${BOOT_CATALOG[$1.$2]:-}"; }
catalog::label()              { catalog::get "$1" label; }
catalog::description()        { catalog::get "$1" description; }
catalog::versions()           { catalog::get "$1" versions; }
catalog::targets()            { catalog::get "$1" targets; }
catalog::configs()            { catalog::get "$1" configs; }
catalog::default_version()    { catalog::get "$1" default_version; }

# --- predicates -------------------------------------------------------------

catalog::is_service() {
  local s
  for s in "${BOOT_SERVICE_ORDER[@]}"; do
    [[ "$s" == "$1" ]] && return 0
  done
  return 1
}

catalog::has_version() {
  local v
  for v in ${BOOT_CATALOG[$1.versions]//,/ }; do
    [[ "$v" == "$2" ]] && return 0
  done
  return 1
}

catalog::has_target() {
  local t
  for t in ${BOOT_CATALOG[$1.targets]//,/ }; do
    [[ "$t" == "$2" ]] && return 0
  done
  return 1
}

catalog::has_config() {
  local k
  for k in ${BOOT_CATALOG[$1.configs]//,/ }; do
    [[ "$k" == "$2" ]] && return 0
  done
  return 1
}

# --- config-option details --------------------------------------------------
# Each spec is "label|type|default|choices". catalog::config_get reads one
# field. Used by the wizard questions and by --config validation.

catalog::config_get() {
  local spec="${BOOT_CATALOG_CFG[$1.$2]:-}"
  local label type def choices
  IFS='|' read -r label type def choices <<< "$spec"
  case "$3" in
    label)   printf '%s' "$label" ;;
    type)    printf '%s' "$type" ;;
    default) printf '%s' "$def" ;;
    choices) printf '%s' "$choices" ;;
  esac
}

# catalog::sort_csv <csv> — sort comma-separated items so multi-select
# (checklist) values are canonical regardless of selection order.
catalog::sort_csv() {
  local -a items=()
  local i
  for i in ${1//,/ }; do items+=("$i"); done
  local -a sorted
  mapfile -t sorted < <(printf '%s\n' "${items[@]}" | LC_ALL=C sort)
  local out=""
  for i in "${sorted[@]}"; do
    [[ -z "$i" ]] && continue
    out+="${out:+,}$i"
  done
  printf '%s' "$out"
}

# catalog::validate_config <svc> <key> <value> — prints an explanation and
# returns 1 when invalid; prints nothing and returns 0 when valid.
catalog::validate_config() {
  local svc="$1" key="$2" value="$3"
  local type def choices
  type="$(catalog::config_get "$svc" "$key" type)"
  def="$(catalog::config_get "$svc" "$key" default)"
  choices="$(catalog::config_get "$svc" "$key" choices)"

  case "$type" in
    bool)
      case "$value" in
        on|off|yes|no|true|false|1|0) return 0 ;;
        *) printf 'expected on/off (default: %s)' "$def"; return 1 ;;
      esac
      ;;
    int)
      if [[ "$value" =~ ^-?[0-9]+$ ]]; then
        return 0
      else
        printf 'expected a whole number (default: %s)' "$def"; return 1
      fi
      ;;
    select)
      local c
      for c in ${choices//,/ }; do
        [[ "$c" == "$value" ]] && return 0
      done
      printf 'must be one of: %s (default: %s)' "$choices" "$def"; return 1
      ;;
    checklist)
      local item c ok
      for item in ${value//,/ }; do
        ok=0
        for c in ${choices//,/ }; do
          [[ "$c" == "$item" ]] && ok=1 && break
        done
        [[ "$ok" == "1" ]] || { printf 'unknown choice: %s (choices: %s)' "$item" "$choices"; return 1; }
      done
      return 0
      ;;
    string|*)
      return 0
      ;;
  esac
}

# --- load the per-service meta files ----------------------------------------
for _booooot_svc in "${BOOT_SERVICE_ORDER[@]}"; do
  # shellcheck disable=SC1090
  source "$BOOT_ROOT/services/$_booooot_svc/meta.sh"
done
unset _booooot_svc
