#!/usr/bin/env bash
# direct.sh — the "tin" (direct-to-host) target strategy (tasks 011 + 012).
#
# Direct installs go through apt (lib/apt.sh): tooling, repos/PPAs, package
# install, config, then start + probe. Steps are registered into the engine
# with engine::add_step, so the engine owns framing, dry-run and outcome
# logging. Services may override any piece through hooks
# (svc_<name>::apt_packages, svc_<name>::apt_repos, svc_<name>::config_apply)
# — the service modules (015-021) flesh those out; this file provides the
# defaults.
#
# Every step function has the engine signature:
#   <fn> <svc> <version> <target> <config_csv> <arg>

# direct::install_steps <svc> <version> <target> <config_csv> — register the
# install steps for a service on the tin.
direct::install_steps() {
  local svc="$1" version="$2" target="$3" config_csv="${4:-}"
  local label; label="$(catalog::label "$svc")"

  direct::_register_repos "$svc" "$version"
  engine::add_step "ensure apt tooling" direct::_ensure_tooling
  if [[ -n "${APT_HOOKS[pre-update]:-}" ]]; then
    engine::add_step "pre-update hooks ($svc)" direct::_run_hooks_pre_update
  fi
  engine::add_step "update apt package lists" apt::update
  if [[ -n "${APT_HOOKS[pre-install]:-}" ]]; then
    engine::add_step "pre-install hooks ($svc)" direct::_run_hooks_pre_install
  fi
  engine::add_step "install $label $version" direct::_install_packages
  if [[ -n "${APT_HOOKS[post-install]:-}" ]]; then
    engine::add_step "post-install hooks ($svc)" direct::_run_hooks_post_install
  fi
  engine::add_step "configure $label" direct::config_apply
  engine::add_step "start & verify $label" direct::_start_service
}

# direct::uninstall_steps <svc> <target> — register the uninstall steps.
direct::uninstall_steps() {
  local svc="$1" target="$2"
  local label; label="$(catalog::label "$svc")"
  engine::add_step "stop $label" direct::_stop_service
  engine::add_step "purge $label packages" direct::_remove_packages
  engine::add_step "remove $label config" direct::_remove_config
}

# --- install step functions -----------------------------------------------------

# direct::_ensure_tooling — make sure curl / gnupg / lsb-release exist (the
# binaries repo & PPA setup needs).
direct::_ensure_tooling() {
  local -a missing=()
  cmd::exists curl || missing+=(curl)
  cmd::exists gpg || missing+=(gpg)
  cmd::exists lsb_release || missing+=(lsb_release)
  if (( ${#missing[@]} == 0 )); then
    ENGINE_STEP_DETAIL="tooling present (curl, gnupg, lsb-release)"
    return 0
  fi
  if [[ "$BOOT_DRY_RUN" == "1" ]]; then
    ENGINE_STEP_DETAIL="would install: ${missing[*]}"
    return 0
  fi
  local m
  for m in "${missing[@]}"; do
    case "$m" in
      curl)        apt::ensure_tool curl curl ;;
      gpg)         apt::ensure_tool gpg gnupg ;;
      lsb_release) apt::ensure_tool lsb_release lsb-release ;;
    esac
  done
  ENGINE_STEP_DETAIL="installed tooling: ${missing[*]}"
  return 0
}

# direct::_install_packages — resolve this version's packages and install them
# (idempotent: already-installed → skip).
direct::_install_packages() {
  local svc="$1" version="$2" config_csv="${4:-}"
  local pkgs
  pkgs="$(apt::resolve_packages "$svc" "$version" "$config_csv")"
  [[ -n "$pkgs" ]] || die BOOT-2004 "no packages resolved for $svc $version"
  # intentional word-splitting: each token is a package name
  # shellcheck disable=SC2086
  apt::install $pkgs
}

# --- repo / PPA steps ------------------------------------------------------------

# direct::_register_repos <svc> <version> — register the "add repositories"
# step when the service needs any.
direct::_register_repos() {
  local svc="$1" version="$2" specs
  if declare -F "svc_${svc}::apt_repos" >/dev/null 2>&1; then
    specs="$( "svc_${svc}::apt_repos" "$version" )"
  else
    specs="$(direct::_default_repos "$svc" "$version")"
  fi
  [[ -n "$specs" ]] || return 0
  engine::add_step "add apt repositories ($svc)" direct::_add_repos "$specs"
}

# direct::_add_repos <svc> <version> <target> <config_csv> <specs> — add every
# repo/PPA in the spec (one "repo|name|key|source" or "ppa|name" per line).
direct::_add_repos() {
  local specs="${5:-}" line kind
  local -a added=() skipped=()
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    kind="${line%%|*}"
    case "$kind" in
      repo)
        local name key_url source_line rest
        rest="${line#repo|}"
        name="${rest%%|*}"; rest="${rest#*|}"
        key_url="${rest%%|*}"; rest="${rest#*|}"
        source_line="$rest"
        if apt::ensure_repo "$name" "$key_url" "$source_line"; then
          added+=("$name")
        else
          skipped+=("$name")
        fi
        ;;
      ppa)
        local ppa="${line#ppa|}"
        if apt::ensure_ppa "$ppa"; then
          added+=("$ppa")
        else
          skipped+=("$ppa")
        fi
        ;;
    esac
  done <<< "$specs"
  if [[ "$BOOT_DRY_RUN" == "1" ]]; then
    ENGINE_STEP_DETAIL="would add: ${added[*]:-${skipped[*]}}"
    return 0
  fi
  if (( ${#added[@]} == 0 )); then
    ENGINE_STEP_DETAIL="already configured: ${skipped[*]}"
    return 1
  fi
  ENGINE_STEP_DETAIL="added ${added[*]}${skipped:+, ${skipped[*]} already configured}"
  return 0
}

# direct::_default_repos <svc> <version> — built-in repo/PPA table (temporary;
# the per-service modules 015-021 replace it). mysql/postgresql/nginx/varnish
# install from the distro for now — their official repos land with the service
# tasks.
direct::_default_repos() {
  local svc="$1" version="$2" maj
  case "$svc" in
    php)
      printf 'ppa|ondrej/php\n'
      ;;
    node)
      maj="${version%%.*}"; [[ "$maj" == "current" ]] && maj="22"
      printf 'repo|nodesource|https://deb.nodesource.com/gpgkey/nodesource.gpg.key|deb [signed-by=%s] https://deb.nodesource.com/node_%s.x nodistro main\n' \
        "$(apt::_keyring_path nodesource)" "$maj"
      ;;
    elasticsearch)
      maj="${version%%.*}"
      printf 'repo|elasticsearch|https://artifacts.elastic.co/GPG-KEY-elasticsearch|deb [signed-by=%s] https://artifacts.elastic.co/packages/%s/apt stable main\n' \
        "$(apt::_keyring_path elasticsearch)" "$maj"
      ;;
    *) : ;;
  esac
}

# --- hooks ----------------------------------------------------------------------

direct::_run_hooks_pre_update()  { apt::run_hooks pre-update    "$1" "$2" "$4"; ENGINE_STEP_DETAIL="pre-update hooks ran"; }
direct::_run_hooks_pre_install() { apt::run_hooks pre-install   "$1" "$2" "$4"; ENGINE_STEP_DETAIL="pre-install hooks ran"; }
direct::_run_hooks_post_install() { apt::run_hooks post-install "$1" "$2" "$4"; ENGINE_STEP_DETAIL="post-install hooks ran"; }

# --- config, service control, uninstall -------------------------------------------

# direct::config_apply <svc> <version> <target> <config_csv> <arg> — write the
# service config. Real templates land in task 014; this creates the config dir
# (the engine records the chosen options in the manifest). Services may
# override with svc_<name>::config_apply.
direct::config_apply() {
  local svc="$1" version="$2" config_csv="${4:-}"
  if declare -F "svc_${svc}::config_apply" >/dev/null 2>&1; then
    "svc_${svc}::config_apply" "$svc" "$version" "$config_csv"
    return 0
  fi
  local dir; dir="$(direct::_config_dir "$svc")"
  if [[ "$BOOT_DRY_RUN" == "1" ]]; then
    ENGINE_STEP_DETAIL="would write $svc config ($dir; templates land in task 014)"
    return 0
  fi
  if [[ -d "$dir" ]]; then
    ENGINE_STEP_DETAIL="config dir $dir already exists (templates land in task 014)"
    return 1
  fi
  apt::_sudo mkdir -p "$dir" || die BOOT-3001 "could not create config dir: $dir"
  ENGINE_STEP_DETAIL="created config dir $dir (templates land in task 014)"
  return 0
}

# direct::_start_service — start/enable the unit, then confirm via the probe.
direct::_start_service() {
  local svc="$1" version="$2"
  local unit; unit="$(direct::_unit "$svc" "$version")"
  if [[ "$BOOT_DRY_RUN" == "1" ]]; then
    ENGINE_STEP_DETAIL="would start ${unit:-$svc}"
    return 0
  fi
  if [[ -z "$unit" ]]; then
    ENGINE_STEP_DETAIL="$svc has no service unit to start"
    return 0
  fi
  if ! cmd::exists systemctl; then
    ENGINE_STEP_DETAIL="systemctl not found — cannot start $unit"
    return 0
  fi
  if ! apt::_sudo systemctl enable --now "$unit" 2>/dev/null && ! apt::_sudo systemctl start "$unit" 2>/dev/null; then
    out::_logfile error "could not start $unit"
    die BOOT-2005 "could not start $unit" "check: journalctl -u $unit"
  fi
  if direct::status "$svc" "$unit"; then
    ENGINE_STEP_DETAIL="$unit running"
  else
    ENGINE_STEP_DETAIL="$unit started but probe says not running"
    return 1
  fi
  return 0
}

# direct::_stop_service — stop/disable the unit on uninstall.
direct::_stop_service() {
  local svc="$1" version="$2"
  local unit; unit="$(direct::_unit "$svc" "$version")"
  if [[ "$BOOT_DRY_RUN" == "1" ]]; then
    ENGINE_STEP_DETAIL="would stop ${unit:-$svc}"
    return 0
  fi
  if [[ -z "$unit" ]]; then
    ENGINE_STEP_DETAIL="$svc has no service unit to stop"
    return 0
  fi
  if ! cmd::exists systemctl; then
    ENGINE_STEP_DETAIL="systemctl not found — cannot stop $unit"
    return 0
  fi
  if apt::_sudo systemctl disable --now "$unit" 2>/dev/null || apt::_sudo systemctl stop "$unit" 2>/dev/null; then
    ENGINE_STEP_DETAIL="$unit stopped"
  else
    ENGINE_STEP_DETAIL="$unit not running (nothing to stop)"
  fi
  return 0
}

# direct::_remove_packages — purge this version's packages (purge also removes
# their config).
direct::_remove_packages() {
  local svc="$1" version="$2"
  local pkgs
  pkgs="$(apt::resolve_packages "$svc" "$version" "")"
  if [[ -z "$pkgs" ]]; then
    ENGINE_STEP_DETAIL="no packages resolved for $svc $version"
    return 0
  fi
  if [[ "$BOOT_DRY_RUN" == "1" ]]; then
    ENGINE_STEP_DETAIL="would purge: $pkgs"
    return 0
  fi
  # shellcheck disable=SC2086
  if ! apt::_run env DEBIAN_FRONTEND=noninteractive apt-get purge -y $pkgs; then
    out::_logfile error "apt-get purge failed ($svc): $(printf '%s' "$APT_ERR" | tail -n 5)"
    die BOOT-2002 "apt-get purge failed: $svc" "$(printf '%s' "$APT_ERR" | tail -n 3 | sed 's/^/    /')"
  fi
  ENGINE_STEP_DETAIL="purged: $pkgs"
  return 0
}

# direct::_remove_config — remove booooot-managed config dirs only (system
# dirs are cleaned up by the purge).
direct::_remove_config() {
  local svc="$1"
  local dir; dir="$(direct::_config_dir "$svc")"
  if [[ "$dir" != /etc/booooot/* ]]; then
    ENGINE_STEP_DETAIL="system config kept ($dir) — the purge removes it"
    return 0
  fi
  if [[ "$BOOT_DRY_RUN" == "1" ]]; then
    ENGINE_STEP_DETAIL="would remove config dir $dir"
    return 0
  fi
  if [[ -d "$dir" ]]; then
    apt::_sudo rm -rf "$dir"
    ENGINE_STEP_DETAIL="removed config dir $dir"
  else
    ENGINE_STEP_DETAIL="no config dir at $dir"
    return 1
  fi
  return 0
}

# --- probing ---------------------------------------------------------------------

# direct::status <svc> [unit] — probe whether the service is running on the
# host. Returns 0 running, 1 not running, 2 unknown (cannot probe).
direct::status() {
  local svc="$1" unit="${2:-}"
  [[ -n "$unit" ]] || unit="$(direct::_unit "$svc" "$(state::field "$svc" version "")")"
  [[ -n "$unit" ]] || return 2
  cmd::exists systemctl || return 2
  systemctl is-active --quiet "$unit" 2>/dev/null && return 0
  return 1
}

# --- per-service facts ------------------------------------------------------------

# direct::_unit <svc> <version> — the systemd unit for a service ('' = none).
direct::_unit() {
  case "$1" in
    php)           printf 'php%s-fpm' "${2:-}" ;;
    mysql)         printf 'mysql' ;;
    postgresql)    printf 'postgresql' ;;
    nginx)         printf 'nginx' ;;
    elasticsearch) printf 'elasticsearch' ;;
    varnish)       printf 'varnish' ;;
    node)          printf '' ;;
    *)             printf '%s' "$1" ;;
  esac
}

# direct::_config_dir <svc> — the host config directory for a service.
direct::_config_dir() {
  case "$1" in
    php)           printf '/etc/php' ;;
    mysql)         printf '/etc/mysql' ;;
    postgresql)    printf '/etc/postgresql' ;;
    nginx)         printf '/etc/nginx' ;;
    node)          printf '/etc/booooot/node' ;;
    elasticsearch) printf '/etc/elasticsearch' ;;
    varnish)       printf '/etc/varnish' ;;
    *)             printf '/etc/booooot/%s' "$1" ;;
  esac
}
