#!/usr/bin/env bash

set -uo pipefail

MODE="standard"
URL=""
INPUT_URL=""
NO_POPUP=0
KEEP_CLIPBOARD=0
KEEP_CLIPBOARD_SET=0
APP_MODE=0
JSON_OUTPUT=0

EXIT_INVALID_URL=2
EXIT_MISSING_DEP=3
EXIT_SUMMARIZE_FAIL=4

SUMMARY_FILE="/tmp/yt-skim-last-summary.txt"
META_FILE="/tmp/yt-skim-last-meta.json"
TTL_SECONDS=1800
CODEX_BIN=""
SOURCE_KIND=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF_USAGE'
Usage:
  yt-skim.sh [--mode short|standard|structured] [--url <url>] [--input-url <url>] [--no-popup] [--keep-clipboard] [--app-mode] [--json]

Options:
  --mode            Summary format (default: standard)
  --url             Supported link (YouTube or X). If omitted, reads from clipboard.
  --input-url       Alias of --url for app integration.
  --no-popup        Skip "Open full summary?" prompt.
  --keep-clipboard  Keep original clipboard content.
  --app-mode        Disable notification/dialog side effects.
  --json            Emit one JSON object to stdout.
  -h, --help        Show this help text.
EOF_USAGE
}

notify() {
  (( APP_MODE == 1 )) && return 0
  command -v osascript >/dev/null 2>&1 || return 0
  local title="$1"
  local message="$2"
  osascript -e "display notification \"${message//\"/\\\"}\" with title \"${title//\"/\\\"}\"" >/dev/null 2>&1 || true
}

error_notify() {
  local message="$1"
  notify "YT Skim" "$message"
}

cleanup_old_tmp() {
  local now file mtime age
  now="$(date +%s)"
  for file in "$SUMMARY_FILE" "$META_FILE"; do
    [[ -f "$file" ]] || continue
    mtime="$(stat -f %m "$file" 2>/dev/null || echo "$now")"
    age=$((now - mtime))
    if (( age > TTL_SECONDS )); then
      rm -f "$file"
    fi
  done
}

check_deps() {
  local missing=0
  local missing_list=""
  local dep
  local deps=(summarize)

  if (( APP_MODE == 0 )); then
    deps+=(osascript)
    if [[ -z "$URL" && -z "$INPUT_URL" ]]; then
      deps+=(pbpaste)
    fi
    if (( KEEP_CLIPBOARD == 0 )); then
      deps+=(pbcopy)
    fi
  fi

  for dep in "${deps[@]}"; do
    if ! command -v "$dep" >/dev/null 2>&1; then
      echo "Missing dependency: $dep" >&2
      missing_list+="${dep} "
      missing=1
    fi
  done

  if [[ -z "$CODEX_BIN" ]]; then
    echo "Missing dependency: codex" >&2
    missing_list+="codex "
    missing=1
  fi

  if (( missing == 1 )); then
    if (( JSON_OUTPUT == 1 )); then
      emit_json_error "MISSING_DEP" "Couldn't summarize. Missing dependency." "Missing dependency: ${missing_list%% }" "$EXIT_MISSING_DEP"
    fi
    error_notify "Couldn't summarize. Missing dependency."
    exit "$EXIT_MISSING_DEP"
  fi
}

resolve_codex_bin() {
  if command -v codex >/dev/null 2>&1; then
    CODEX_BIN="$(command -v codex)"
    return
  fi
  if [[ -x "/Applications/Codex.app/Contents/Resources/codex" ]]; then
    export PATH="/Applications/Codex.app/Contents/Resources:$PATH"
    if command -v codex >/dev/null 2>&1; then
      CODEX_BIN="$(command -v codex)"
      return
    fi
  fi
  CODEX_BIN=""
}

trim_input_url() {
  local raw="$1"
  raw="$(printf '%s' "$raw" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
  raw="$(printf '%s' "$raw" | sed -E 's/^[<("\x27]+//; s/[>)"\x27,.;:!?]+$//')"
  printf '%s' "$raw"
}

is_youtube_url() {
  local u="$1"
  [[ "$u" =~ ^https?://([a-zA-Z0-9-]+\.)?(youtube\.com|youtu\.be)/.+$ ]]
}

is_x_status_url() {
  local u="$1"
  [[ "$u" =~ ^https?://([a-zA-Z0-9-]+\.)?(x\.com|twitter\.com)/([^/]+/status|i/web/status)/[0-9]+([/?#].*)?$ ]]
}

classify_source_url() {
  local u="$1"
  if is_youtube_url "$u"; then
    printf '%s' "youtube"
    return
  fi
  if is_x_status_url "$u"; then
    printf '%s' "x"
    return
  fi
  printf '%s' "unsupported"
}

sanitize_output() {
  sed -E 's/\x1B\[[0-9;]*[A-Za-z]//g' \
  | sed -E 's/\r//g' \
  | awk '
      {
        if ($0 ~ /^[[:space:]]*$/) {
          blank++
          if (blank <= 1) print ""
        } else {
          blank=0
          print
        }
      }
    ' \
  | sed -E '1{/^[[:space:]]*$/d;}; ${/^[[:space:]]*$/d;}'
}

json_escape() {
  printf '%s' "$1" | awk '
    BEGIN { ORS=""; first=1 }
    {
      gsub(/\\/,"\\\\")
      gsub(/"/,"\\\"")
      gsub(/\t/,"\\t")
      gsub(/\r/,"\\r")
      if (!first) printf "\\n"
      printf "%s", $0
      first=0
    }
  '
}

emit_json_success() {
  local summary="$1"
  local source="$2"
  printf '{"ok":true,"summary":"%s","mode":"%s","source":"%s","exit_code":0}\n' \
    "$(json_escape "$summary")" \
    "$(json_escape "$MODE")" \
    "$(json_escape "$source")"
}

emit_json_error() {
  local error_code="$1"
  local message="$2"
  local details="$3"
  local exit_code="$4"
  printf '{"ok":false,"error_code":"%s","message":"%s","details":"%s","exit_code":%s}\n' \
    "$(json_escape "$error_code")" \
    "$(json_escape "$message")" \
    "$(json_escape "$details")" \
    "$exit_code"
}

build_style_instruction() {
  case "$MODE" in
    short)
      printf '%s' "Respond with only 1-2 concise sentences."
      ;;
    standard)
      printf '%s' "Respond with one short paragraph followed by exactly 3 bullet points."
      ;;
    structured)
      printf '%s' "Use exactly these headings: Topic, Key points, Who it's for, Should I watch?. Keep each section concise."
      ;;
    *)
      return 1
      ;;
  esac
}

summarize_link() {
  local source_kind="$1"
  local input_url="$2"
  local style_instruction
  style_instruction="$(build_style_instruction)" || return 1

  if [[ "$source_kind" == "youtube" ]]; then
    summarize "$input_url" \
      --cli codex \
      --plain \
      --youtube auto \
      --length medium \
      --prompt "$style_instruction"
  else
    summarize "$input_url" \
      --cli codex \
      --plain \
      --length medium \
      --prompt "$style_instruction"
  fi
}

is_x_fetch_unavailable_error() {
  local text="$1"
  local lower
  lower="$(printf '%s' "$text" | tr '[:upper:]' '[:lower:]')"

  [[ "$lower" == *"bird not available"* ]] \
    || [[ "$lower" == *"unable to fetch tweet content from x"* ]] \
    || [[ "$lower" == *"nitter returned empty body"* ]] \
    || [[ "$lower" == *"nitter failed"* ]] \
    || [[ "$lower" == *"unable to fetch"* && "$lower" == *"x"* ]]
}

is_auth_error() {
  local text="$1"
  local lower
  lower="$(printf '%s' "$text" | tr '[:upper:]' '[:lower:]')"

  [[ "$lower" == *"codex login"* ]] \
    || [[ "$lower" == *"not logged in"* ]] \
    || [[ "$lower" == *"authentication required"* ]] \
    || [[ "$lower" == *"auth required"* ]] \
    || [[ "$lower" == *"unauthorized"* ]]
}

preview_text() {
  local text="$1"
  printf '%s' "$text" | tr '\n' ' ' | sed -E 's/[[:space:]]+/ /g' | cut -c1-220
}

popup_prompt() {
  osascript <<'EOF_POPUP' 2>/dev/null
tell application "System Events"
  activate
  set d to display dialog "Open full summary?" buttons {"Dismiss", "Open"} default button "Open" with title "YT Skim" with icon note
  return button returned of d
end tell
EOF_POPUP
}

write_meta() {
  local source_url="$1"
  local ts url_hash
  ts="$(date +%s)"
  url_hash="$(printf '%s' "$source_url" | shasum -a 256 | awk '{print $1}')"
  cat >"$META_FILE" <<EOF_META
{"timestamp":$ts,"mode":"$MODE","url_hash":"$url_hash"}
EOF_META
}

parse_args() {
  while (( $# > 0 )); do
    case "$1" in
      --mode)
        [[ $# -ge 2 ]] || { echo "--mode requires a value" >&2; usage; exit 1; }
        MODE="$2"
        shift 2
        ;;
      --url)
        [[ $# -ge 2 ]] || { echo "--url requires a value" >&2; usage; exit 1; }
        URL="$2"
        shift 2
        ;;
      --input-url)
        [[ $# -ge 2 ]] || { echo "--input-url requires a value" >&2; usage; exit 1; }
        INPUT_URL="$2"
        shift 2
        ;;
      --no-popup)
        NO_POPUP=1
        shift
        ;;
      --keep-clipboard)
        KEEP_CLIPBOARD=1
        KEEP_CLIPBOARD_SET=1
        shift
        ;;
      --app-mode)
        APP_MODE=1
        shift
        ;;
      --json)
        JSON_OUTPUT=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "Unknown option: $1" >&2
        usage
        exit 1
        ;;
    esac
  done
}

main() {
  parse_args "$@"
  if (( APP_MODE == 1 )) && (( KEEP_CLIPBOARD_SET == 0 )); then
    KEEP_CLIPBOARD=1
  fi

  cleanup_old_tmp
  resolve_codex_bin
  check_deps

  local source_url
  if [[ -n "$INPUT_URL" ]]; then
    source_url="$INPUT_URL"
  elif [[ -n "$URL" ]]; then
    source_url="$URL"
  else
    if (( APP_MODE == 0 )); then
      source_url="$(pbpaste 2>/dev/null || true)"
    else
      source_url=""
    fi
  fi
  source_url="$(trim_input_url "$source_url")"

  if [[ -z "$source_url" ]]; then
    local details="Clipboard (or --url) is empty."
    echo "$details" >&2
    if (( JSON_OUTPUT == 1 )); then
      emit_json_error "INVALID_URL" "Couldn't summarize. No link found." "$details" "$EXIT_INVALID_URL"
    fi
    error_notify "Couldn't summarize. No link found."
    exit "$EXIT_INVALID_URL"
  fi

  SOURCE_KIND="$(classify_source_url "$source_url")"
  if [[ "$SOURCE_KIND" == "unsupported" ]]; then
    local details="Unsupported URL. Supported links: YouTube and X post URLs. Received: $source_url"
    echo "$details" >&2
    if (( JSON_OUTPUT == 1 )); then
      emit_json_error "UNSUPPORTED_URL" "Couldn't summarize. Only YouTube and X links are supported." "$details" "$EXIT_INVALID_URL"
    fi
    error_notify "Couldn't summarize. Only YouTube and X links are supported."
    exit "$EXIT_INVALID_URL"
  fi

  local output
  if ! output="$(summarize_link "$SOURCE_KIND" "$source_url" 2>&1)"; then
    echo "$output" >&2

    if is_auth_error "$output"; then
      local auth_message="Couldn't summarize. Please run 'codex login' first."
      local auth_details="Codex CLI appears unauthenticated. Open Terminal and run: codex login. Backend output: $output"
      if (( JSON_OUTPUT == 1 )); then
        emit_json_error "BACKEND_FAIL" "$auth_message" "$auth_details" "$EXIT_SUMMARIZE_FAIL"
      fi
      error_notify "$auth_message"
      exit "$EXIT_SUMMARIZE_FAIL"
    fi

    if [[ "$SOURCE_KIND" == "x" ]] && is_x_fetch_unavailable_error "$output"; then
      local x_message="Couldn't summarize this X post. It may be private or require extra fetch support."
      local x_details="Try a public post, or install bird for better X support. Backend output: $output"
      if (( JSON_OUTPUT == 1 )); then
        emit_json_error "X_FETCH_UNAVAILABLE" "$x_message" "$x_details" "$EXIT_SUMMARIZE_FAIL"
      fi
      error_notify "$x_message"
      exit "$EXIT_SUMMARIZE_FAIL"
    fi

    if (( JSON_OUTPUT == 1 )); then
      emit_json_error "BACKEND_FAIL" "Couldn't summarize. Maybe the content saved you some time." "$output" "$EXIT_SUMMARIZE_FAIL"
    fi
    error_notify "Couldn't summarize. Maybe the content saved you some time."
    exit "$EXIT_SUMMARIZE_FAIL"
  fi

  output="$(printf '%s\n' "$output" | sanitize_output)"
  if [[ -z "$output" ]]; then
    local details="Summarize returned empty output."
    echo "$details" >&2
    if (( JSON_OUTPUT == 1 )); then
      emit_json_error "BACKEND_FAIL" "Couldn't summarize. Maybe the content saved you some time." "$details" "$EXIT_SUMMARIZE_FAIL"
    fi
    error_notify "Couldn't summarize. Maybe the content saved you some time."
    exit "$EXIT_SUMMARIZE_FAIL"
  fi

  printf '%s\n' "$output" >"$SUMMARY_FILE"
  write_meta "$source_url"

  if (( KEEP_CLIPBOARD == 0 )) && (( APP_MODE == 0 )); then
    printf '%s' "$output" | pbcopy
  fi

  if (( JSON_OUTPUT == 1 )); then
    emit_json_success "$output" "$SOURCE_KIND"
  fi

  (( APP_MODE == 1 )) && exit 0

  local preview
  preview="$(preview_text "$output")"
  notify "YT Skim" "${preview:-Summary ready.}"

  if (( NO_POPUP == 0 )); then
    local action
    action="$(popup_prompt || true)"
    if [[ "$action" == "Open" ]]; then
      local popup_script="${SCRIPT_DIR}/yt-skim-popup.sh"
      [[ -x "$popup_script" ]] && "$popup_script" >/dev/null 2>&1 || true
    fi
  fi

  exit 0
}

main "$@"
