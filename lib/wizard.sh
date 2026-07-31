#!/usr/bin/env bash
# wizard.sh — thin whiptail/dialog wrappers for the booooot TUI (task 005).
#
# Convention for every wrapper:
#   - OK            → returns 0; the result lands in $BOOT_WIZARD_RESULT
#   - Cancel / ESC  → returns 1 (the caller uses this to go back one screen,
#                      or to quit cleanly with a BOOT-1005 note)
# whiptail/dialog return codes: 0 = OK, 1 = Cancel, 255 = ESC. Both cancels
# are mapped to "back one screen", so every screen has working navigation.
#
# The TUI needs a real Linux terminal (whiptail is not in git bash); non-TTY
# and --no-input runs fail gracefully with a pointer to flag mode. The wrapper
# layer is deliberately thin so a prompt-based fallback is cheap to add later.

BOOT_WIZARD_BACKTITLE="👻 booooot — the friendly server provisioner"
BOOT_WIZARD_RESULT=""
BOOT_WIZARD_BIN=""

# wizard::_backend — resolve whiptail (preferred) or dialog; caches the name.
wizard::_backend() {
  if [[ -z "$BOOT_WIZARD_BIN" ]]; then
    if cmd::exists whiptail; then
      BOOT_WIZARD_BIN="whiptail"
    elif cmd::exists dialog; then
      BOOT_WIZARD_BIN="dialog"
    else
      return 1
    fi
  fi
}

# wizard::require — make sure the wizard can actually run; die gracefully
# (pointing at flag mode) when it can't.
wizard::require() {
  if [[ "$BOOT_NO_INPUT" == "1" ]]; then
    die BOOT-1007 "--no-input was set, but the wizard is interactive." \
        "use flag mode instead: booooot install <service> --target <t> --config k=v"
  fi
  if [[ ! -t 0 ]] || [[ ! -t 1 ]]; then
    die BOOT-1007 "the wizard needs an interactive terminal (whiptail TUI)." \
        "use flag mode instead: booooot install <service> --target <t> --config k=v"
  fi
  if ! wizard::_backend; then
    die BOOT-1006 "neither whiptail nor dialog was found (they are not in git bash)." \
        "install one (e.g. apt install whiptail) or use flag mode: booooot install <service> --target <t>"
  fi
}

# wizard::_run <args...> — run the backend, capture its result into
# BOOT_WIZARD_RESULT, and map 1/255 (cancel/ESC) to return 1.
wizard::_run() {
  BOOT_WIZARD_RESULT=""
  local out="" rc=0
  out="$("$BOOT_WIZARD_BIN" --backtitle "$BOOT_WIZARD_BACKTITLE" "$@" 3>&1 1>&2 2>&3)" || rc=$?
  BOOT_WIZARD_RESULT="$out"
  [[ "$rc" == "0" ]]
}

# wizard::menu <title> <tag> <item> [<tag> <item> …] — single-choice menu.
wizard::menu() {
  local title="$1"; shift
  local args=(--title "$title" --menu "Choose one (ESC to go back):" 0 0 0)
  local tag
  while (( $# > 0 )); do
    tag="$1"; shift
    args+=("$tag" "$1"); shift
  done
  wizard::_run "${args[@]}"
}

# wizard::radio <title> <prompt> <default_tag> <tag> <item> […]
wizard::radio() {
  local title="$1" prompt="$2" default="$3"; shift 3
  local args=()
  if [[ -n "$default" ]]; then
    args+=(--default-item "$default")
  fi
  args+=(--title "$title" --radiolist "$prompt" 0 0 0)
  local tag
  while (( $# > 0 )); do
    tag="$1"; shift
    args+=("$tag" "$1" "OFF"); shift
  done
  wizard::_run "${args[@]}"
}

# wizard::checklist <title> <prompt> <default_csv> <tag> <item> […] —
# multi-select; the result is a comma-separated list of chosen tags.
wizard::checklist() {
  local title="$1" prompt="$2" default_csv="$3"; shift 3
  local -A on=()
  local d
  for d in ${default_csv//,/ }; do on[$d]=1; done
  local args=(--title "$title" --checklist "$prompt" 0 0 0)
  local tag status
  while (( $# > 0 )); do
    tag="$1"; shift
    status="OFF"
    [[ -n "${on[$tag]:-}" ]] && status="ON"
    args+=("$tag" "$1" "$status"); shift
  done
  if wizard::_run "${args[@]}"; then
    # whiptail returns quoted, space-separated tags: "curl" "zip"
    BOOT_WIZARD_RESULT="$(printf '%s' "$BOOT_WIZARD_RESULT" | tr -d '"' | tr -s ' ' | sed 's/^ //; s/ $//' | tr ' ' ',')" || true
    return 0
  fi
  return 1
}

# wizard::input <title> <prompt> [initial]
wizard::input() {
  local title="$1" prompt="$2" initial="${3:-}"
  if wizard::_run --title "$title" --inputbox "$prompt" 0 0 "$initial"; then
    BOOT_WIZARD_RESULT="${BOOT_WIZARD_RESULT%"${BOOT_WIZARD_RESULT##*[![:space:]]}"}"
    return 0
  fi
  return 1
}

# wizard::confirm <text> [default_no] — yes/no prompt. 0 = yes, 1 = no/ESC.
wizard::confirm() {
  local text="$1" defaultno="${2:-0}"
  local args=(--title "Confirm" --yesno "$text" 0 0)
  [[ "$defaultno" == "1" ]] && args+=(--defaultno)
  wizard::_run "${args[@]}"
}

# wizard::msg <title> <text> — informational screen (OK to continue).
wizard::msg() {
  local title="$1" text="$2"
  wizard::_run --title "$title" --msgbox "$text" 0 0
}

# wizard::summary <title> <text> — plan summary before anything "happens".
wizard::summary() {
  wizard::msg "$1" "$2"
}
