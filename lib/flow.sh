#!/usr/bin/env bash
# flow.sh — the install/uninstall flows, wizard and flag forms (task 007).
#
# The wizard path (booooot wizard) and the flag path (booooot install …)
# both funnel through plan::* so identical inputs always produce identical
# plans. Confirming a plan hands off to the install engine (task 011), which
# executes it for real (or in dry-run when --dry-run is set). Cancel/ESC at
# any step walks back one screen; at the top it quits cleanly with a
# BOOT-1005 note instead of an error.

# flow::menu_service <install|uninstall> — pick a service from the catalog.
flow::menu_service() {
  local mode="$1"
  local -a pairs=()
  local s
  for s in $(catalog::services); do
    pairs+=("$s" "$(catalog::label "$s") — $(str::truncate "$(catalog::description "$s")" 46)")
  done
  wizard::menu "booooot — $mode: which service?" "${pairs[@]}"
}

# flow::menu_version <svc> — pick a version (radio, default preselected).
flow::menu_version() {
  local svc="$1"
  local label versions def
  label="$(catalog::label "$svc")"
  versions="$(catalog::versions "$svc")"
  def="$(catalog::default_version "$svc")"
  local -a pairs=()
  local v
  for v in ${versions//,/ }; do
    pairs+=("$v" "$label $v")
  done
  wizard::radio "Which $label version?" "Choose a version (ESC to go back):" "$def" "${pairs[@]}"
}

# flow::menu_target — pick an install target.
flow::menu_target() {
  wizard::radio "Install target" "Where should it run? (ESC to go back):" "direct" \
    "direct" "Direct to host (the tin)" \
    "docker" "Docker container" \
    "vm"     "VM (later)"
}

# flow::menu_uninstall_target — pick where a service is installed.
flow::menu_uninstall_target() {
  wizard::radio "Remove from" "Where is it installed? (ESC to go back):" "direct" \
    "direct" "Direct to host (the tin)" \
    "docker" "Docker container" \
    "vm"     "VM (later)"
}

# flow::ask_config <svc> <version> <target> <cfg_assoc> — ask every catalog
# config question for a service. Prefills from values already in the assoc so
# backing up and re-entering keeps prior answers. Returns 1 (back to the
# target menu) if the user cancels any question.
flow::ask_config() {
  local svc="$1" version="$2" target="$3"
  local -n _cfg="$4"
  local cfg_keys key type label def choices cur
  cfg_keys="$(catalog::configs "$svc")"
  for key in ${cfg_keys//,/ }; do
    type="$(catalog::config_get "$svc" "$key" type)"
    label="$(catalog::config_get "$svc" "$key" label)"
    def="$(catalog::config_get "$svc" "$key" default)"
    choices="$(catalog::config_get "$svc" "$key" choices)"
    cur="${_cfg[$key]:-$def}"

    case "$type" in
      bool)
        local defno=0
        [[ "$cur" == "off" ]] && defno=1
        if wizard::confirm "$label?" "$defno"; then _cfg[$key]="on"; else _cfg[$key]="off"; fi
        ;;
      select)
        local -a pairs=()
        local c
        for c in ${choices//,/ }; do pairs+=("$c" "$c"); done
        if wizard::radio "$label" "Choose a value (ESC to go back):" "$cur" "${pairs[@]}"; then
          _cfg[$key]="$BOOT_WIZARD_RESULT"
        else
          return 1
        fi
        ;;
      checklist)
        local -a pairs=()
        local c
        for c in ${choices//,/ }; do pairs+=("$c" "$c"); done
        if wizard::checklist "$label" "Select (space toggles, ESC to go back):" "$cur" "${pairs[@]}"; then
          _cfg[$key]="$(catalog::sort_csv "$BOOT_WIZARD_RESULT")"
        else
          return 1
        fi
        ;;
      int|string|*)
        if wizard::input "$label" "$label (ESC to go back):" "$cur"; then
          _cfg[$key]="$BOOT_WIZARD_RESULT"
        else
          return 1
        fi
        ;;
    esac
  done
  return 0
}

# flow::install_wizard — full interactive install flow (dry-run). Returns when
# the plan is confirmed (0) or the user backs out to the top (also 0, with a
# BOOT-1005 note printed).
flow::install_wizard() {
  local svc="" version="" target=""
  local -A cfg=()

  while :; do
    if ! flow::menu_service "install"; then
      out::warn "cancelled (BOOT-1005) — nothing was changed."
      return 0
    fi
    svc="$BOOT_WIZARD_RESULT"

    while :; do
      if ! flow::menu_version "$svc"; then break; fi
      version="$BOOT_WIZARD_RESULT"

      while :; do
        if ! flow::menu_target; then break; fi
        target="$BOOT_WIZARD_RESULT"
        cfg=()

        while :; do
          if ! flow::ask_config "$svc" "$version" "$target" cfg; then break; fi
          local config_lines plan_text
          config_lines="$(plan::config_lines cfg)"
          plan_text="$(plan::install_text "$svc" "$version" "$target" "$config_lines")"

          if ! wizard::summary "Install plan" \
              "booooot would install $(catalog::label "$svc") $version → $target.

$plan_text

Nothing is changed yet — confirm below to install for real."; then
            break
          fi

          if wizard::confirm "Install $(catalog::label "$svc") $version via $target?"; then
            engine::install "$svc" "$version" "$target" "$config_lines"
            return 0
          fi
          # No / ESC on confirm → back to the config questions to edit.
        done
      done
    done
  done
}

# flow::uninstall_wizard — full interactive uninstall flow (dry-run).
flow::uninstall_wizard() {
  local svc="" target=""
  while :; do
    if ! flow::menu_service "uninstall"; then
      out::warn "cancelled (BOOT-1005) — nothing was changed."
      return 0
    fi
    svc="$BOOT_WIZARD_RESULT"

    while :; do
      if ! flow::menu_uninstall_target; then break; fi
      target="$BOOT_WIZARD_RESULT"
      local plan_text
      plan_text="$(plan::uninstall_text "$svc" "$target")"

      if ! wizard::summary "Uninstall plan" \
          "booooot would uninstall $(catalog::label "$svc") from $target.

$plan_text

Nothing will actually be removed — this is a dry run."; then
        break
      fi

      if wizard::confirm "Uninstall $(catalog::label "$svc") from $target? (dry-run)"; then
        plan::uninstall "$svc" "$target"
        out::ok "BOOT-0000 dry-run complete — nothing was removed."
        return 0
      fi
      # No / ESC on confirm → re-ask where it's installed.
    done
  done
}
