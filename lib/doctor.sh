#!/usr/bin/env bash
# doctor.sh — health checks + first-aid command (task 009).
#
# `booooot doctor` runs a small registry of checks and prints a colour-coded,
# line-stable report. Every line follows the same shape so it's safe to grep
# or feed to a script:
#
#   [✓] BOOT-0000 distro check — Ubuntu 24.04 supported
#   [~] BOOT-1201 distro check — Fedora 40 not Debian/Ubuntu — dev/test mode only
#   [✗] BOOT-1204 php state — php not running but marked installed — try `booooot doctor --fix php`
#
# Interface phase = stub registry: checks only do safe reads (platform::id,
# command -v, the state manifest via lib/state.sh) — nothing touches a real
# system. Real probes (ports, service units, versions) land with the install
# engine (011+); the fixes library (024) plugs in behind `--fix`.

# --- check registry ----------------------------------------------------------
# Run order. Each check function prints its own report line(s); passing checks
# always report BOOT-0000 so green lines stay uniform and greppable. The
# failing code for each check is defined next to the check below.
BOOT_DOCTOR_CHECKS=(distro bash tools manifest config)

# --- run state ---------------------------------------------------------------
BOOT_DOCTOR_PASS=0
BOOT_DOCTOR_WARN=0
BOOT_DOCTOR_FAIL=0
BOOT_DOCTOR_INFO=0

# doctor::_line <status> <code> <name> <detail...> — one report line.
# status: pass | warn | fail | info (drives the glyph, colour and counters).
doctor::_line() {
  local status="$1" code="$2" name="$3"; shift 3
  local glyph color
  case "$status" in
    pass) glyph="✓"; color="$C_OK";    BOOT_DOCTOR_PASS=$((BOOT_DOCTOR_PASS + 1)) ;;
    warn) glyph="~"; color="$C_WARN";  BOOT_DOCTOR_WARN=$((BOOT_DOCTOR_WARN + 1)) ;;
    fail) glyph="✗"; color="$C_ERROR"; BOOT_DOCTOR_FAIL=$((BOOT_DOCTOR_FAIL + 1)) ;;
    *)    glyph="·"; color="$C_MUTED"; BOOT_DOCTOR_INFO=$((BOOT_DOCTOR_INFO + 1)) ;;
  esac
  color::paint "$color" "[$glyph] $code"
  printf " %s — %s\n" "$name" "$*"
}

# --- checks ------------------------------------------------------------------

# distro — booooot targets Debian/Ubuntu. Non-Debian is a warn (dev/test mode
# is supported; see `booooot version`), not a hard fail.
doctor::check_distro() {
  local id name
  id="$(platform::id)"
  name="$(platform::pretty_name)"; [[ -n "$name" ]] || name="$id"
  if platform::is_debian_family; then
    doctor::_line pass "BOOT-0000" "distro check" "$name supported"
  else
    doctor::_line warn "BOOT-1201" "distro check" "$name not Debian/Ubuntu — dev/test mode only"
  fi
}

# bash — booooot needs bash 4+. (The entrypoint already refuses to start
# below 4, so this stays green in practice — it documents the requirement.)
doctor::check_bash() {
  if (( BASH_VERSINFO[0] >= 4 )); then
    doctor::_line pass "BOOT-0000" "bash check" "bash $BASH_VERSION OK (need 4+)"
  else
    doctor::_line fail "BOOT-1202" "bash check" "bash $BASH_VERSION too old — need bash 4+"
  fi
}

# tools — required binaries on PATH. apt-get is essential (host installs go
# through it); whiptail is only needed for the TUI wizard, so its absence is
# a warn, not a fail.
doctor::check_tools() {
  local core=() opt=()
  cmd::exists apt-get || core+=(apt-get)
  cmd::exists whiptail || opt+=(whiptail)
  if (( ${#core[@]} > 0 )); then
    doctor::_line fail "BOOT-1203" "tools check" "missing: ${core[*]} — booooot targets apt-based systems"
  elif (( ${#opt[@]} > 0 )); then
    doctor::_line warn "BOOT-1203" "tools check" "whiptail not found — wizard needs it, flag mode still works"
  else
    doctor::_line pass "BOOT-0000" "tools check" "core tools present (apt-get, whiptail)"
  fi
}

# manifest — state consistency (safe reads only). No manifest → info (a fresh
# machine, not a problem). Malformed → fail BOOT-5001. Installed-but-not-
# running services → one fail line each with a --fix hint; all consistent →
# a single green line.
doctor::check_manifest() {
  local file="${1:-$BOOT_STATE_FILE}"
  if [[ ! -f "$file" || ! -r "$file" ]]; then
    doctor::_line info "BOOT-1205" "state check" "no manifest at $file — nothing installed yet"
    return 0
  fi
  if ! state::load "$file"; then
    doctor::_line fail "BOOT-5001" "state check" "manifest not valid JSON: $file"
    return 0
  fi

  local svc bad=0 n_inst=0 n_run=0
  for svc in $(catalog::services); do
    if state::installed "$svc"; then
      n_inst=$((n_inst + 1))
      if [[ "$(state::field "$svc" running false)" == "true" ]]; then
        n_run=$((n_run + 1))
      else
        doctor::_line fail "BOOT-1204" "$svc state" \
          "$svc not running but marked installed — try \`booooot doctor --fix $svc\`"
        bad=$((bad + 1))
      fi
    fi
  done
  if (( bad == 0 )); then
    doctor::_line pass "BOOT-0000" "state check" "manifest consistent — $n_inst installed, $n_run running"
  fi
}

# config — template-vs-expected checks land in Phase 2. Registered as a stub
# so the check list is complete; reports info, never fails.
doctor::check_config() {
  doctor::_line info "BOOT-1206" "config check" "config sanity vs templates lands in Phase 2"
}

# --- --fix -------------------------------------------------------------------

# doctor::fix <svc> [state_file] — dry-run stub for a one-command fix.
# Diagnoses (safe reads only) what the fix would address, then reports a
# dry-run message. The real fixes library (024) replaces this body.
doctor::fix() {
  local svc="$1" file="${2:-$BOOT_STATE_FILE}"
  if ! catalog::is_service "$svc"; then
    die BOOT-1004 "unknown service: $svc" \
        "known services: $(catalog::services_csv) (see 'booooot list')"
  fi

  if [[ -f "$file" && -r "$file" ]] && state::load "$file"; then
    if state::installed "$svc" && [[ "$(state::field "$svc" running false)" != "true" ]]; then
      out::error "BOOT-1204 $svc — marked installed but not running (state: $file)"
    elif state::installed "$svc"; then
      out::ok "$svc is installed and running — nothing to fix."
      return 0
    else
      out::info "$svc is not installed — no fix needed."
      return 0
    fi
  else
    out::info "no state manifest at $file — nothing to fix yet."
  fi

  out::warn "BOOT-0001 fix for '$svc' is a dry-run stub — the fixes library lands in task 024."
  out::info "meanwhile: booooot install $svc --target direct --dry-run  (plan only)"
}

# --- render ------------------------------------------------------------------

# doctor::render — run every check in registry order and print the report.
# Exits 1 when any check failed (handy for scripts); 0 otherwise.
doctor::render() {
  art::header
  out::section "Doctor — health check"
  local check
  for check in "${BOOT_DOCTOR_CHECKS[@]}"; do
    "doctor::check_$check"
  done
  printf "\n"
  out::info "doctor: $BOOT_DOCTOR_PASS pass · $BOOT_DOCTOR_WARN warn · $BOOT_DOCTOR_FAIL fail · $BOOT_DOCTOR_INFO info"
  if (( BOOT_DOCTOR_FAIL > 0 )); then
    out::info "some issues are fixable: booooot doctor --fix <service>  (dry-run stub for now)"
    return 1
  fi
  return 0
}
