#!/usr/bin/env bash
# apt.sh — direct-target apt machinery (task 012).
#
# Everything the "tin" (direct) target needs to install software on a
# Debian/Ubuntu host through apt, safely and re-runnably:
#
#   apt::update / apt::install        — idempotent; skip when already satisfied.
#   apt::ensure_repo / apt::ensure_ppa — add official repos/PPAs with rollback
#       on failure (a half-added repo is worse than none).
#   apt::resolve_packages             — version "8.3" → concrete apt packages.
#   apt::add_hook / apt::run_hooks    — pre/post hooks for services that need
#       to do something around apt (the service modules 015-021 register these).
#
# Everything honours $BOOT_DRY_RUN (real no-op) and runs under sudo when
# required, preferring non-interactive (-n) so it never hangs on a prompt.
# Debian/Ubuntu only — see platform::is_debian_family.

BOOT_APT_STAMP="${BOOT_APT_STAMP:-$BOOT_HOME/.last-apt-update}"
APT_ERR=""

# --- privilege ----------------------------------------------------------------

# apt::_sudo <cmd...> — run a command as root for non-apt file operations
# (curl, mv, tee, rm). Already root → run directly; otherwise prefer `sudo -n`
# (non-interactive) and fall back to plain sudo. Dies BOOT-1006 when there is
# no privilege path at all.
apt::_sudo() {
  if [[ "$(id -u)" == "0" ]]; then
    "$@"
    return 0
  fi
  if ! cmd::exists sudo; then
    die BOOT-1006 "sudo not found (and not running as root) — direct installs need root"
  fi
  if sudo -n "$@" 2>/dev/null; then
    return 0
  fi
  sudo "$@"
}

# apt::_run <cmd...> — run an apt command as root, capturing its output into
# APT_ERR and returning its exit status. The privilege check happens *before*
# any capture, so a missing sudo never has its error swallowed by a
# redirection or command substitution.
apt::_run() {
  local out rc=0
  if [[ "$(id -u)" == "0" ]]; then
    out="$( "$@" 2>&1 )" || rc=$?
  elif ! cmd::exists sudo; then
    die BOOT-1006 "sudo not found (and not running as root) — direct installs need root"
  else
    out="$(sudo -n "$@" 2>&1)" || rc=$?
    if (( rc != 0 )); then
      out="$(sudo "$@" 2>&1)" || rc=$?
    fi
  fi
  APT_ERR="$out"
  return "$rc"
}

# --- idempotent apt operations -------------------------------------------------

# apt::fresh <max_age_s> — true when apt-get update has run within max_age_s
# seconds (tracked by a stamp file in BOOT_HOME), so repeated runs can skip it.
apt::fresh() {
  local max_age="${1:-3600}" stamp now then
  stamp="${BOOT_APT_STAMP:-$BOOT_HOME/.last-apt-update}"
  [[ -f "$stamp" ]] || return 1
  now="$(date +%s 2>/dev/null)" || return 1
  then="$(date -r "$stamp" +%s 2>/dev/null)" || return 1
  (( now - then < max_age ))
}

# apt::_run_update — run `apt-get update` for real (no dry-run), capturing the
# output into APT_ERR. Returns apt's exit status.
apt::_run_update() {
  apt::_run env DEBIAN_FRONTEND=noninteractive apt-get update
}

# apt::update [--force] — refresh apt package lists. Skips (idempotent) when
# the lists were refreshed recently, unless --force is given (used right after
# adding a repo, when a refresh is mandatory). Fails with BOOT-2001.
apt::update() {
  local force=0
  [[ "${1:-}" == "--force" ]] && force=1
  if [[ "$BOOT_DRY_RUN" == "1" ]]; then
    ENGINE_STEP_DETAIL="would run: apt-get update"
    return 0
  fi
  if (( ! force )) && apt::fresh 3600; then
    ENGINE_STEP_DETAIL="apt lists refreshed recently — skipping"
    return 1
  fi
  if ! apt::_run_update; then
    out::_logfile error "apt-get update failed: $(printf '%s' "$APT_ERR" | tail -n 5)"
    die BOOT-2001 "apt-get update failed" "$(printf '%s' "$APT_ERR" | tail -n 3 | sed 's/^/    /')"
  fi
  : > "$BOOT_APT_STAMP" 2>/dev/null || true
  ENGINE_STEP_DETAIL="apt package lists updated"
  return 0
}

# apt::satisfied <pkg> — true when the package is installed (dpkg status).
# Read-only; safe to call in dry-run.
apt::satisfied() {
  local pkg="$1" st
  st="$(dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null)" || return 1
  [[ "$st" == *"install ok installed"* ]]
}

# apt::install <pkgs...> — idempotent install. Already-satisfied packages are
# skipped; if every package is satisfied this is a no-op that reports so.
# Fails with BOOT-2002. Runs non-interactively (DEBIAN_FRONTEND).
apt::install() {
  local -a missing=()
  local p
  for p in "$@"; do
    apt::satisfied "$p" || missing+=("$p")
  done
  if (( ${#missing[@]} == 0 )); then
    ENGINE_STEP_DETAIL="already installed: $*"
    return 1   # skip-with-reason (idempotent)
  fi
  if [[ "$BOOT_DRY_RUN" == "1" ]]; then
    ENGINE_STEP_DETAIL="would install: ${missing[*]}"
    return 0
  fi
  if ! apt::_run env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${missing[@]}"; then
    out::_logfile error "apt-get install failed (${missing[*]}): $(printf '%s' "$APT_ERR" | tail -n 5)"
    die BOOT-2002 "apt-get install failed: ${missing[*]}" "$(printf '%s' "$APT_ERR" | tail -n 3 | sed 's/^/    /')"
  fi
  ENGINE_STEP_DETAIL="installed: ${missing[*]}"
  return 0
}

# apt::ensure_tool <cmd> <pkg> — make sure a helper binary exists, installing
# the package that provides it when it doesn't (used for curl, gnupg,
# lsb-release, add-apt-repository).
apt::ensure_tool() {
  local cmd="$1" pkg="$2"
  if cmd::exists "$cmd"; then
    return 0
  fi
  if [[ "$BOOT_DRY_RUN" == "1" ]]; then
    ENGINE_STEP_DETAIL="would install $pkg (needed for $cmd)"
    return 0
  fi
  if ! apt::_run env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$pkg"; then
    out::_logfile error "could not install $pkg (needed for $cmd): $(printf '%s' "$APT_ERR" | tail -n 5)"
    die BOOT-2002 "could not install $pkg (needed for $cmd)" "$(printf '%s' "$APT_ERR" | tail -n 3 | sed 's/^/    /')"
  fi
  return 0
}

# --- repo / PPA management -----------------------------------------------------

# apt::_keyring_path <name> — where ensure_repo installs the signing key.
apt::_keyring_path() { printf '/usr/share/keyrings/%s-archive-keyring.gpg' "$1"; }

# apt::ensure_repo <name> <key_url> <source_line> — idempotently add an apt
# source: fetch the signing key into a keyring, write a sources.list.d entry,
# then refresh. If anything fails partway, the partial additions are removed
# (rollback) so the host is never left half-configured. Fails with BOOT-2003
# and logs the exact apt error.
apt::ensure_repo() {
  local name="$1" key_url="$2" source_line="$3"
  local keyring srcfile
  keyring="$(apt::_keyring_path "$name")"
  srcfile="/etc/apt/sources.list.d/${name}.list"
  if [[ -f "$srcfile" ]] && [[ -f "$keyring" ]]; then
    ENGINE_STEP_DETAIL="apt repo '$name' already configured"
    return 1
  fi
  if [[ "$BOOT_DRY_RUN" == "1" ]]; then
    ENGINE_STEP_DETAIL="would add apt repo: $name"
    return 0
  fi
  apt::ensure_tool curl curl
  apt::ensure_tool gpg gnupg
  local -a added=()
  if ! apt::_sudo curl -fsSL "$key_url" -o "${keyring}.tmp" 2>&1; then
    die BOOT-2003 "could not fetch signing key for repo '$name'" "$key_url"
  fi
  apt::_sudo mv "${keyring}.tmp" "$keyring"
  added+=("$keyring")
  local srctmp="${srcfile}.tmp.$$"
  printf 'deb [signed-by=%s] %s\n' "$keyring" "$source_line" > "$srctmp"
  if ! apt::_sudo mv "$srctmp" "$srcfile"; then
    apt::_sudo rm -f "${added[@]}"
    die BOOT-2003 "could not write apt source for repo '$name'" "$srcfile"
  fi
  added+=("$srcfile")
  if ! apt::_run_update; then
    apt::_sudo rm -f "${added[@]}"
    out::_logfile error "apt update failed after adding repo '$name': $(printf '%s' "$APT_ERR" | tail -n 5)"
    die BOOT-2003 "apt update failed after adding repo '$name' — rolled back" "$(printf '%s' "$APT_ERR" | tail -n 3 | sed 's/^/    /')"
  fi
  ENGINE_STEP_DETAIL="added apt repo: $name"
  return 0
}

# apt::ensure_ppa <ppa> — idempotently add a Launchpad PPA (e.g. ondrej/php)
# via add-apt-repository. Fails with BOOT-2003 and logs the exact error.
apt::ensure_ppa() {
  local ppa="$1"
  if ls /etc/apt/sources.list.d/*"${ppa//\//-}"*.list >/dev/null 2>&1; then
    ENGINE_STEP_DETAIL="PPA '$ppa' already added"
    return 1
  fi
  if [[ "$BOOT_DRY_RUN" == "1" ]]; then
    ENGINE_STEP_DETAIL="would add PPA: $ppa"
    return 0
  fi
  apt::ensure_tool add-apt-repository software-properties-common
  local err
  if ! err="$(DEBIAN_FRONTEND=noninteractive apt::_sudo add-apt-repository -y "ppa:$ppa" 2>&1)"; then
    out::_logfile error "add-apt-repository failed for $ppa: $(printf '%s' "$err" | tail -n 5)"
    die BOOT-2003 "could not add PPA '$ppa'" "$(printf '%s' "$err" | tail -n 3 | sed 's/^/    /')"
  fi
  apt::update --force
  ENGINE_STEP_DETAIL="added PPA: $ppa"
  return 0
}

# --- package-version resolution ------------------------------------------------

# apt::resolve_packages <svc> <version> [config_csv] — print the concrete apt
# packages that install a catalog service at a given version. Services may
# provide their own mapping (svc_<name>::apt_packages <version> <config_csv>,
# tasks 015-021); until then a built-in table covers the catalog so resolution
# works for any service today.
apt::resolve_packages() {
  local svc="$1" version="$2" config_csv="${3:-}"
  if declare -F "svc_${svc}::apt_packages" >/dev/null 2>&1; then
    "svc_${svc}::apt_packages" "$version" "$config_csv"
    return 0
  fi
  apt::_default_packages "$svc" "$version" "$config_csv"
}

# apt::_default_packages <svc> <version> <config_csv> — built-in base mapping
# (temporary; replaced by the per-service modules in 015-021). A resolution
# that comes up empty is a hard error (BOOT-2004) — better to stop than guess.
apt::_default_packages() {
  local svc="$1" version="$2" config_csv="${3:-}" maj
  case "$svc" in
    php)
      apt::_php_packages "$version" "$config_csv"
      ;;
    mysql)
      printf 'mysql-server-%s mysql-client-%s\n' "$version" "$version"
      ;;
    postgresql)
      maj="${version%%.*}"
      printf 'postgresql-%s postgresql-client-%s\n' "$maj" "$maj"
      ;;
    nginx)
      printf 'nginx\n'
      ;;
    node)
      printf 'nodejs\n'
      ;;
    elasticsearch)
      printf 'elasticsearch\n'
      ;;
    varnish)
      printf 'varnish\n'
      ;;
    *)
      die BOOT-2004 "no package mapping for service '$svc'" "service modules land in tasks 015-021"
      ;;
  esac
}

# apt::_php_packages <version> <config_csv> — php8.3, php8.3-cli, php8.3-fpm,
# plus php8.3-<ext> for every enabled extension in the config.
apt::_php_packages() {
  local version="$1" config_csv="${2:-}" ext e
  printf 'php%s php%s-cli php%s-fpm' "$version" "$version" "$version"
  ext="$(apt::_config_value "$config_csv" extensions)"
  if [[ -n "$ext" ]]; then
    for e in ${ext//,/ }; do
      [[ -n "$e" ]] && printf ' php%s-%s' "$version" "$e"
    done
  fi
  printf '\n'
}

# apt::_config_value <config_lines> <key> — print the value of one key=value
# line (config_lines is newline-separated "key=value", as produced by
# plan::config_lines). Prints nothing when the key is absent.
apt::_config_value() {
  local cfg="$1" key="$2" line k v
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    k="${line%%=*}"; v="${line#*=}"
    if [[ "$k" == "$key" ]]; then
      printf '%s' "$v"
      return 0
    fi
  done <<< "$cfg"
  return 0
}

# --- pre/post hooks -------------------------------------------------------------

# Services that need to do something around apt (add a signing key, run
# `update-ca-certificates`, enable a daemon, …) register hook functions. Hooks
# are called as: <fn> <svc> <version> <config_csv>.
declare -A APT_HOOKS=()

# apt::add_hook <when> <fn> — register a hook.
# when: pre-update | post-update | pre-install | post-install.
apt::add_hook() {
  local when="$1" fn="$2"
  APT_HOOKS[$when]="${APT_HOOKS[$when]:-}${APT_HOOKS[$when]:+ }$fn"
}

# apt::run_hooks <when> <svc> <version> <config_csv> — run every registered
# hook for a phase, in order. A failing hook aborts with BOOT-2002.
apt::run_hooks() {
  local when="$1" svc="$2" version="$3" config_csv="${4:-}" fn
  for fn in ${APT_HOOKS[$when]:-}; do
    "$fn" "$svc" "$version" "$config_csv" || die BOOT-2002 "hook '$fn' failed ($when)"
  done
}
