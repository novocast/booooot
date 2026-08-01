#!/usr/bin/env bash
# engine.sh — the install engine: plan → target → strategy → steps → state
# (task 011).
#
# The engine turns a plan (task 007) into executed work behind a *target
# abstraction*: `direct` (tin), `docker`, `vm`. Each target provides a
# strategy (install / uninstall / config_apply / status probe) with a
# consistent step shape; the engine owns framing, dry-run, idempotency and
# manifest updates.
#
#   - Strategies register steps with engine::add_step; engine::run_steps
#     executes them. Every step succeeds, fails (die with a BOOT- code), or
#     is skipped-with-reason (idempotent).
#   - $BOOT_DRY_RUN is honoured at engine level: identical step output, no
#     side effects, no manifest write.
#   - The manifest is written only after every step succeeds; a failed run
#     leaves it untouched.
#
# The VM target is stubbed here and fleshed out with the test-VM work (026);
# the docker target is stubbed until the compose generator lands (013). The
# direct (tin) target is real — see lib/direct.sh + lib/apt.sh (task 012).

# --- engine state (per run) ---------------------------------------------------
ENGINE_SVC=""
ENGINE_VERSION=""
ENGINE_TARGET=""
ENGINE_CONFIG=""
ENGINE_STEPS=()        # step labels
ENGINE_STEP_FNS=()     # step functions
ENGINE_STEP_ARGS=()    # per-step arg (a single string; '' when none)
ENGINE_STEP_DETAIL=""  # set by the running step, printed as the outcome
ENGINE_FAILED=0

# engine::strategy <target> — print the strategy prefix for a target.
engine::strategy() {
  case "$1" in
    direct) printf 'direct' ;;
    docker) printf 'docker' ;;
    vm)     printf 'vm' ;;
    *)      return 1 ;;
  esac
}

# engine::add_step <label> <fn> [arg] — register one step. The step function
# is later called as: <fn> <svc> <version> <target> <config_csv> <arg>.
# It returns 0 (ok), 1 (skip-with-reason, ENGINE_STEP_DETAIL set) or calls
# die on failure.
engine::add_step() {
  ENGINE_STEPS+=("$1")
  ENGINE_STEP_FNS+=("$2")
  ENGINE_STEP_ARGS+=("${3:-}")
}

# engine::_reset — clear per-run state.
engine::_reset() {
  ENGINE_SVC=""
  ENGINE_VERSION=""
  ENGINE_TARGET=""
  ENGINE_CONFIG=""
  ENGINE_STEPS=()
  ENGINE_STEP_FNS=()
  ENGINE_STEP_ARGS=()
  ENGINE_STEP_DETAIL=""
  ENGINE_FAILED=0
}

# engine::run_steps — execute the registered steps in order. Stops at the
# first hard failure; skipped steps (return 1) continue.
engine::run_steps() {
  local total="${#ENGINE_STEPS[@]}" i fn arg rc
  for (( i = 0; i < total; i++ )); do
    fn="${ENGINE_STEP_FNS[$i]}"
    arg="${ENGINE_STEP_ARGS[$i]}"
    ENGINE_STEP_DETAIL=""
    out::step "$((i + 1))" "$total" "${ENGINE_STEPS[$i]}"
    rc=0
    "$fn" "$ENGINE_SVC" "$ENGINE_VERSION" "$ENGINE_TARGET" "$ENGINE_CONFIG" "$arg" || rc=$?
    case "$rc" in
      0) out::ok "${ENGINE_STEP_DETAIL:-done}" ;;
      1) out::info "skip — ${ENGINE_STEP_DETAIL:-already satisfied}" ;;
      *) out::error "engine step failed: ${ENGINE_STEP_DETAIL:-unknown error}"
         return 1 ;;
    esac
  done
  return 0
}

# engine::_load_state — load the manifest (malformed → BOOT-5001). A missing
# manifest is fine (fresh machine).
engine::_load_state() {
  if [[ -f "$BOOT_STATE_FILE" ]]; then
    state::load "$BOOT_STATE_FILE" || die BOOT-5001 "state manifest is not valid JSON: $BOOT_STATE_FILE"
  fi
}

# engine::install <svc> <version> <target> <config_csv> — execute an install
# plan. Idempotent (already installed → no-op with a clear message). Honours
# $BOOT_DRY_RUN; the manifest is written only after every step succeeds.
engine::install() {
  local svc="$1" version="$2" target="$3" config_csv="${4:-}"
  local label; label="$(catalog::label "$svc")"
  engine::_load_state

  if state::installed "$svc"; then
    if [[ "$(state::field "$svc" target "")" == "$target" ]]; then
      out::info "$label already installed (version $(state::field "$svc" version "$version"), target $target) — nothing to do."
      return 0
    fi
    out::warn "$label is installed via $(state::field "$svc" target "") — reinstalling via $target will replace it."
  fi

  local prefix
  prefix="$(engine::strategy "$target")" || die BOOT-1004 "unsupported target: $target"

  engine::_reset
  ENGINE_SVC="$svc"; ENGINE_VERSION="$version"; ENGINE_TARGET="$target"; ENGINE_CONFIG="$config_csv"
  "${prefix}::install_steps" "$svc" "$version" "$target" "$config_csv"

  if [[ "$BOOT_DRY_RUN" == "1" ]]; then
    out::section "Dry-run — $label $version via $target"
  else
    out::section "Installing — $label $version via $target"
  fi

  engine::run_steps || return 1

  if [[ "$BOOT_DRY_RUN" == "1" ]]; then
    out::ok "BOOT-0000 dry-run complete — nothing was installed."
    return 0
  fi

  engine::_record_install "$svc" "$version" "$target"
  out::ok "$label $version installed via $target."
  return 0
}

# engine::uninstall <svc> <target> — remove an installed service. No-op when
# not installed. Honours $BOOT_DRY_RUN; the manifest is written only after
# every step succeeds.
engine::uninstall() {
  local svc="$1" target="$2"
  local label; label="$(catalog::label "$svc")"
  engine::_load_state

  if ! state::installed "$svc"; then
    out::info "$label is not installed — nothing to remove."
    return 0
  fi
  local version; version="$(state::field "$svc" version "")"

  local prefix
  prefix="$(engine::strategy "$target")" || die BOOT-1004 "unsupported target: $target"

  engine::_reset
  ENGINE_SVC="$svc"; ENGINE_VERSION="$version"; ENGINE_TARGET="$target"
  ENGINE_CONFIG="$(state::field "$svc" config "")"
  "${prefix}::uninstall_steps" "$svc" "$target"

  if [[ "$BOOT_DRY_RUN" == "1" ]]; then
    out::section "Dry-run — removing $label from $target"
  else
    out::section "Removing — $label from $target"
  fi

  engine::run_steps || return 1

  if [[ "$BOOT_DRY_RUN" == "1" ]]; then
    out::ok "BOOT-0000 dry-run complete — nothing was removed."
    return 0
  fi

  state::remove "$svc"
  state::save "$BOOT_STATE_FILE" || die BOOT-5002 "could not write state manifest: $BOOT_STATE_FILE"
  out::ok "$label removed from $target."
  return 0
}

# engine::status <svc> — run the strategy's status probe for a service (which
# target it probes depends on the manifest).
engine::status() {
  local svc="$1"
  engine::_load_state
  local target; target="$(state::field "$svc" target "direct")"
  local prefix
  prefix="$(engine::strategy "$target")" || die BOOT-1004 "unsupported target: $target"
  "${prefix}::status" "$svc"
}

# engine::_record_install <svc> <version> <target> — write the installed
# service into the manifest (called only after all steps succeed).
engine::_record_install() {
  local svc="$1" version="$2" target="$3"
  state::set "$svc" installed "true"
  state::set "$svc" version "$version"
  state::set "$svc" target "$target"
  state::set "$svc" running "true"
  state::set "$svc" updated_at "$(date '+%Y-%m-%d %H:%M:%S')"
  state::save "$BOOT_STATE_FILE" || die BOOT-5002 "could not write state manifest: $BOOT_STATE_FILE"
}

# --- docker target (stub until task 013) ---------------------------------------
# The compose generator (013) replaces these with real steps; until then the
# dry-run shows the planned shape and live runs fail with a clear code.
docker::install_steps() {
  if [[ "$BOOT_DRY_RUN" != "1" ]]; then
    die BOOT-4001 "docker target not implemented yet" "the docker-compose generator lands in task 013 — use --target direct for now"
  fi
  local svc="$1" version="$2"
  engine::add_step "generate docker-compose.yml" engine::_stub_step "would write compose for $svc:$version (task 013)"
  engine::add_step "pull images"                engine::_stub_step "would pull $svc:$version (task 013)"
  engine::add_step "start container"            engine::_stub_step "would start booooot-$svc (task 013)"
}

docker::uninstall_steps() {
  if [[ "$BOOT_DRY_RUN" != "1" ]]; then
    die BOOT-4001 "docker target not implemented yet" "the docker-compose generator lands in task 013 — use --target direct for now"
  fi
  local svc="$1"
  engine::add_step "stop container"   engine::_stub_step "would stop booooot-$svc (task 013)"
  engine::add_step "remove container" engine::_stub_step "would remove booooot-$svc (task 013)"
}

docker::status() {
  out::warn "docker target not implemented yet — cannot probe (task 013)"
  return 1
}

# --- vm target (stub until task 026) --------------------------------------------
vm::install_steps() {
  if [[ "$BOOT_DRY_RUN" != "1" ]]; then
    die BOOT-0001 "vm target not implemented yet" "the test-VM work lands in task 026 — use --target direct for now"
  fi
  local svc="$1" version="$2"
  engine::add_step "provision VM"  engine::_stub_step "would provision a VM for $svc (task 026)"
  engine::add_step "install in VM" engine::_stub_step "would install $svc $version in the VM (task 026)"
}

vm::uninstall_steps() {
  if [[ "$BOOT_DRY_RUN" != "1" ]]; then
    die BOOT-0001 "vm target not implemented yet" "the test-VM work lands in task 026 — use --target direct for now"
  fi
  local svc="$1"
  engine::add_step "tear down VM" engine::_stub_step "would tear down the $svc VM (task 026)"
}

vm::status() {
  out::warn "vm target not implemented yet — cannot probe (task 026)"
  return 1
}

# engine::_stub_step <svc> <version> <target> <config_csv> <arg> — dry-run
# step for targets whose real work lands later.
engine::_stub_step() {
  ENGINE_STEP_DETAIL="${5:-not implemented yet}"
  return 0
}
