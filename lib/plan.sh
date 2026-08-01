#!/usr/bin/env bash
# plan.sh — canonical install/uninstall plan printer (task 007).
#
# Both the wizard path and the flag path build the same inputs (service,
# version, target, sorted config csv) and call these functions, so identical
# inputs always produce identical plans — and Phase 2's real engine can reuse
# the exact same format.

# plan::config_lines <assoc_name> — print "key=value" pairs as sorted,
# newline-separated lines (sorted so config order never changes the plan;
# newlines rather than commas so values may contain commas).
plan::config_lines() {
  local -n _map="$1"
  local -a keys
  mapfile -t keys < <(printf '%s\n' "${!_map[@]}" | LC_ALL=C sort)
  local k
  for k in "${keys[@]}"; do
    [[ -z "$k" ]] && continue
    printf '%s=%s\n' "$k" "${_map[$k]}"
  done
}

# plan::_lines <svc> <version> <target> <config_lines> <pad> [profile] — the
# plain (colour-free) body of an install plan. Shared by the console, file
# and msgbox variants so they can never drift apart.
plan::_lines() {
  local svc="$1" version="$2" target="$3" config_lines="$4" pad="$5" profile="${6:-}"
  printf "%s%-12s %s\n" "$pad" "service:" "$svc"
  printf "%s%-12s %s\n" "$pad" "version:" "${version:-latest}"
  printf "%s%-12s %s\n" "$pad" "target:" "${target:-direct}"
  if [[ -n "$config_lines" ]]; then
    printf "%s%-12s\n" "$pad" "config:"
    local -a clines=()
    mapfile -t clines <<< "$config_lines"
    local kv k v
    for kv in "${clines[@]}"; do
      [[ -z "$kv" ]] && continue
      k="${kv%%=*}"; v="${kv#*=}"
      printf "%s    %-12s %s\n" "$pad" "$k" "$v"
    done
  fi
  if [[ -n "$profile" ]]; then
    printf "%s%-12s %s\n" "$pad" "profile:" "$profile"
  fi
  if [[ "$BOOT_DRY_RUN" == "1" ]]; then
    printf "%s%-12s %s\n" "$pad" "mode:" "dry-run (nothing will be installed)"
  else
    printf "%s%-12s %s\n" "$pad" "mode:" "install"
  fi
}

# plan::install <svc> <version> <target> <config_lines> [profile] — coloured
# console install plan.
plan::install() {
  local svc="$1" version="${2:-}" target="${3:-}" config_lines="${4:-}" profile="${5:-}"
  out::section "Install plan"
  plan::_lines "$svc" "$version" "$target" "$config_lines" "  " "$profile"
}

# plan::install_text <svc> <version> <target> <config_lines> — plain text plan
# for the wizard summary screen.
plan::install_text() {
  local svc="$1" version="${2:-}" target="${3:-}" config_lines="${4:-}"
  plan::_lines "$svc" "$version" "$target" "$config_lines" ""
}

# plan::write <file> <svc> <version> <target> <config_lines> [profile] — dump a
# plain plan to a file for test assertions (--plan-file).
plan::write() {
  local file="$1"; shift
  {
    printf '== Install plan ==\n'
    plan::_lines "$@"
  } > "$file"
}

# plan::_unlines <svc> <target> <pad> — plain uninstall plan body.
plan::_unlines() {
  local svc="$1" target="$2" pad="$3"
  printf "%s%-12s %s\n" "$pad" "service:" "$svc"
  printf "%s%-12s %s\n" "$pad" "target:" "${target:-direct}"
  if [[ "$BOOT_DRY_RUN" == "1" ]]; then
    printf "%s%-12s %s\n" "$pad" "mode:" "dry-run (nothing will be removed)"
  else
    printf "%s%-12s %s\n" "$pad" "mode:" "uninstall"
  fi
}

# plan::uninstall <svc> <target> — coloured console uninstall plan.
plan::uninstall() {
  local svc="$1" target="${2:-}"
  out::section "Uninstall plan"
  plan::_unlines "$svc" "$target" "  "
}

# plan::uninstall_text <svc> <target> — plain text uninstall plan.
plan::uninstall_text() {
  local svc="$1" target="${2:-}"
  plan::_unlines "$svc" "$target" ""
}

# plan::uninstall_write <file> <svc> <target> — dump an uninstall plan to file.
plan::uninstall_write() {
  local file="$1" svc="$2" target="${3:-}"
  {
    printf '== Uninstall plan ==\n'
    plan::_unlines "$svc" "$target" ""
  } > "$file"
}
