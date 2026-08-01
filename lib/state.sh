#!/usr/bin/env bash
# state.sh — the booooot state manifest (task 008).
#
# Reads (and, from Phase 2, writes) ~/.booooot/state.json — the single source
# of truth for what's installed, what version, and whether it's running.
# `booooot status` reads it through this module; the install engine (011) and
# the idempotency work (023) build on top of it. This task only implements
# the read side; lib/state.sh is intended to become the single writer later,
# with every install reporting in here.
#
# Parsing is pure bash (no jq): booooot generates the manifest, so the shape
# is known and a small tolerant reader is enough. Strings and whitespace are
# preserved; booleans stay 'true'/'false'; numbers stay verbatim.

# --- loaded state (populated by state::load) ---
STATE_VERSION=""          # top-level "version" field (informational)
STATE_SERVICES=()         # service names present in the manifest
declare -A STATE_FIELDS=()  # STATE_FIELDS["<svc>.<field>"] = value
STATE_LOADED=0            # 1 after a successful state::load

# state::load <file> — read a manifest into the STATE_* globals.
# Returns: 0 loaded | 1 file missing/unreadable | 2 not valid JSON/manifest.
state::load() {
  local file="$1"
  STATE_VERSION=""
  STATE_SERVICES=()
  STATE_FIELDS=()
  STATE_LOADED=0

  if [[ ! -f "$file" || ! -r "$file" ]]; then
    return 1
  fi

  local raw trimmed
  raw="$(<"$file")"
  # trim surrounding whitespace (parameter expansion, not sed/awk)
  trimmed="${raw#"${raw%%[![:space:]]*}"}"
  trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
  [[ "${trimmed:0:1}" == "{" ]] || return 2

  if [[ "$trimmed" =~ \"version\"[[:space:]]*:[[:space:]]*([0-9]+) ]]; then
    STATE_VERSION="${BASH_REMATCH[1]}"
  fi

  local services_body=""
  services_body="$(state::_object_value "$trimmed" services)" || return 2

  local remainder svc body
  remainder="$services_body"
  while state::_next_entry "$remainder"; do
    svc="$_STATE_ENTRY_NAME"
    body="$_STATE_ENTRY_BODY"
    remainder="$_STATE_ENTRY_REST"
    STATE_SERVICES+=("$svc")
    state::_parse_fields "$svc" "$body"
  done

  STATE_LOADED=1
  return 0
}

# state::field <svc> <field> [default] — read one manifest field.
state::field() {
  local svc="$1" field="$2" def="${3:-}"
  printf '%s' "${STATE_FIELDS[$svc.$field]:-$def}"
}

# state::installed <svc> — true when the manifest marks the service installed.
state::installed() {
  [[ "${STATE_FIELDS[$1.installed]:-}" == "true" ]]
}

# --- internal parsing helpers -------------------------------------------------
# The manifest is small and booooot-shaped, so these avoid a full JSON parser.
# They work on literal tokens (parameter expansion, not regex position math),
# balance braces by hand, and ignore CRLF/whitespace between tokens; values
# with spaces survive because strings are quoted.

# state::_object_value <text> <key> — print the body of the object that is the
# value of a top-level '"<key>": { … }'. Prints nothing when the key is absent
# (returns 0); returns 1 when the braces don't balance (malformed).
state::_object_value() {
  local text="$1" key="$2"
  local token="\"${key}\""
  local rest="${text#*$token}"
  [[ "$rest" != "$text" ]] || return 0    # key absent → treat as empty
  rest="${rest#"${rest%%[![:space:]]*}"}" # trim leading whitespace
  rest="${rest#:}"                        # strip the ':' separator
  rest="${rest#"${rest%%[![:space:]]*}"}" # trim again
  [[ "${rest:0:1}" == "{" ]] || return 1  # value must be an object
  rest="${rest:1}"                        # drop the opening '{'
  local depth=0 i ch
  for ((i = 0; i < ${#rest}; i++)); do
    ch="${rest:i:1}"
    if [[ "$ch" == "{" ]]; then
      depth=$((depth + 1))
    elif [[ "$ch" == "}" ]]; then
      if (( depth == 0 )); then
        printf '%s' "${rest:0:i}"
        return 0
      fi
      depth=$((depth - 1))
    fi
  done
  return 1    # found the object but never hit its closing brace
}

# state::_next_entry <body> — peel the first '"name": { … }' entry off an object
# body. Sets _STATE_ENTRY_NAME / _STATE_ENTRY_BODY / _STATE_ENTRY_REST;
# returns 1 when no entry remains.
state::_next_entry() {
  local body="$1"
  local head="${body%%\"*}"        # text before the first '"'
  [[ "$head" != "$body" ]] || return 1    # no key left → done
  local rest="${body#*\"}"         # drop the leading '"'
  local name="${rest%%\"*}"        # the key (up to the closing quote)
  rest="${rest#*\"}"               # drop the key and its closing quote
  rest="${rest#"${rest%%[![:space:]]*}"}"
  rest="${rest#:}"
  rest="${rest#"${rest%%[![:space:]]*}"}"
  [[ "${rest:0:1}" == "{" ]] || return 1  # not an object entry → give up
  rest="${rest:1}"                 # drop the opening '{'
  local depth=0 i ch
  for ((i = 0; i < ${#rest}; i++)); do
    ch="${rest:i:1}"
    if [[ "$ch" == "{" ]]; then
      depth=$((depth + 1))
    elif [[ "$ch" == "}" ]]; then
      if (( depth == 0 )); then
        _STATE_ENTRY_NAME="$name"
        _STATE_ENTRY_BODY="${rest:0:i}"
        _STATE_ENTRY_REST="${rest:i + 1}"
        return 0
      fi
      depth=$((depth - 1))
    fi
  done
  return 1
}

# state::_parse_fields <svc> <entry_body> — store each '"field": value' pair as
# STATE_FIELDS["<svc>.<field>"]. Strings are unquoted; booleans/null and
# numbers are kept verbatim.
state::_parse_fields() {
  local svc="$1" body="$2"
  local re='"([^"]+)"[[:space:]]*:[[:space:]]*("[^"]*"|true|false|null|-?[0-9]+([.][0-9]+)?)'
  local field val full prefix
  while [[ "$body" =~ $re ]]; do
    field="${BASH_REMATCH[1]}"
    val="${BASH_REMATCH[2]}"
    full="${BASH_REMATCH[0]}"
    case "$val" in
      \"*) val="${val#\"}"; val="${val%\"}" ;;
    esac
    STATE_FIELDS["$svc.$field"]="$val"
    # advance past this match (prefix before the match + the match itself)
    prefix="${body%%"$full"*}"
    body="${body:$(( ${#prefix} + ${#full} ))}"
  done
}

# --- writing (install engine, tasks 011/023) ------------------------------------
# The manifest is written only by booooot: the engine records state after a
# successful install/uninstall. Writes are atomic — a temp file in the same
# directory is renamed over the target, so a crash never leaves a half-written
# manifest. STATE_SERVICES / STATE_FIELDS are the in-memory source of truth.

# state::set <svc> <field> <value> — set one field in memory (persist with
# state::save). Marks the service present in STATE_SERVICES.
state::set() {
  local svc="$1" field="$2" value="$3" s
  STATE_FIELDS[$svc.$field]="$value"
  for s in "${STATE_SERVICES[@]}"; do
    [[ "$s" == "$svc" ]] && return 0
  done
  STATE_SERVICES+=("$svc")
}

# state::remove <svc> — drop a service (and all its fields) from memory.
state::remove() {
  local svc="$1" key
  for key in "${!STATE_FIELDS[@]}"; do
    [[ "$key" == "$svc".* ]] && unset "STATE_FIELDS[$key]"
  done
  local -a kept=() s
  for s in "${STATE_SERVICES[@]}"; do
    [[ "$s" != "$svc" ]] && kept+=("$s")
  done
  STATE_SERVICES=("${kept[@]}")
}

# state::save <file> — write the manifest from STATE_* (atomic replace).
state::save() {
  local file="$1" dir
  dir="$(dirname "$file")"
  mkdir -p "$dir" 2>/dev/null || true
  local tmp="${file}.tmp.$$"
  if ! state::_write "$tmp"; then
    rm -f "$tmp" 2>/dev/null || true
    return 1
  fi
  mv "$tmp" "$file" 2>/dev/null || { rm -f "$tmp" 2>/dev/null || true; return 1; }
  return 0
}

# state::_write <file> — emit the JSON manifest from STATE_* globals.
state::_write() {
  local file="$1"
  {
    printf '{\n'
    printf '  "version": %s,\n' "${STATE_VERSION:-1}"
    printf '  "services": {\n'
    local first=1 svc
    for svc in "${STATE_SERVICES[@]}"; do
      if (( first )); then first=0; else printf ',\n'; fi
      state::_write_service "$svc"
    done
    printf '\n  }\n'
    printf '}\n'
  } > "$file"
}

# state::_write_service <svc> — one '"name": { fields }' block. Strings stay
# quoted; 'true'/'false'/'null' and pure integers stay bare.
state::_write_service() {
  local svc="$1" key field val
  printf '    "%s": {\n' "$svc"
  local -a keys=()
  mapfile -t keys < <(printf '%s\n' "${!STATE_FIELDS[@]}" | LC_ALL=C sort)
  local n=0
  for key in "${keys[@]}"; do
    [[ "$key" == "$svc".* ]] || continue
    field="${key#*.}"
    val="${STATE_FIELDS[$key]}"
    if (( n )); then printf ',\n'; fi
    case "$val" in
      true|false|null) printf '      "%s": %s' "$field" "$val" ;;
      ''|*[!0-9]*)     printf '      "%s": "%s"' "$field" "$val" ;;
      *)               printf '      "%s": %s' "$field" "$val" ;;
    esac
    n=$((n + 1))
  done
  printf '\n    }'
}
