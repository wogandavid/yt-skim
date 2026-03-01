#!/usr/bin/env bash

set -uo pipefail

SUMMARY_FILE="/tmp/yt-skim-last-summary.txt"

notify() {
  local title="$1"
  local message="$2"
  osascript -e "display notification \"${message//\"/\\\"}\" with title \"${title//\"/\\\"}\"" >/dev/null 2>&1 || true
}

if ! command -v osascript >/dev/null 2>&1; then
  echo "Missing dependency: osascript" >&2
  exit 3
fi

if [[ ! -s "$SUMMARY_FILE" ]]; then
  notify "YT Skim" "No recent summary found."
  exit 0
fi

# AppleScript dialog text has practical size limits; trim to keep it reliable.
SUMMARY_TEXT="$(cat "$SUMMARY_FILE")"
SUMMARY_TEXT="$(printf '%s' "$SUMMARY_TEXT" | head -c 12000)"

osascript <<EOF >/dev/null 2>&1
tell application "System Events"
  activate
  display dialog "$(
    printf '%s' "$SUMMARY_TEXT" \
    | sed 's/\\/\\\\/g; s/"/\\"/g'
  )" buttons {"Close"} default button "Close" with title "YT Skim Summary"
end tell
EOF

exit 0
