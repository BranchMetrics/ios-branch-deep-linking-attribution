#!/usr/bin/env bash
#
# format-test-results.sh
#
# Parses an `xcodebuild test` log file and emits a single markdown table row
# summarizing the run, useful for pasting into review notes or PR
# descriptions after a local run of the TestBed-GPTDriverTests target.
#
# Usage:
#   ./format-test-results.sh <path-to-xcodebuild-log>
#
# Optional environment overrides (auto-detected from the log when possible):
#   SDK_VERSION   — version string to print in the row (default: <unknown>)
#   DESTINATION   — destination string to print in the row (default: parsed
#                   from the log or <unknown>)
#   PLAN_NAME     — test plan name to print as a small note (default: parsed)
#
# Output: one markdown table row, e.g.
#   | 2026-04-15 | 3.14.0 | iPhone 16 / iOS 18.4 | ✅ pass | 37 | 0 | 2 | 15m 24s |
#
# Exit code: 0 always (so the helper never breaks a CI pipeline). The row's
# Result column reflects the underlying xcodebuild exit when present in the
# log via "xcodebuild exit=N".

set -uo pipefail

LOG_FILE="${1:-}"

if [[ -z "$LOG_FILE" ]]; then
  echo "usage: $0 <path-to-xcodebuild-log>" >&2
  exit 0
fi

if [[ ! -f "$LOG_FILE" ]]; then
  echo "error: log file not found: $LOG_FILE" >&2
  exit 0
fi

# ---- counts ----
# `grep -c` always outputs a number on its own; the `|| true` swallows the
# non-zero exit code that grep returns when there are zero matches, so this
# never triggers `set -e` style behaviour from a calling script.
PASSED=$(grep -cE "^Test Case .* passed " "$LOG_FILE" 2>/dev/null || true)
FAILED=$(grep -cE "^Test Case .* failed " "$LOG_FILE" 2>/dev/null || true)
SKIPPED=$(grep -cE "^Test Case .* skipped " "$LOG_FILE" 2>/dev/null || true)
PASSED=${PASSED:-0}
FAILED=${FAILED:-0}
SKIPPED=${SKIPPED:-0}

# ---- runtime ----
# xcodebuild prints lines like:
#   Executed 39 tests, with 2 tests skipped and 0 failures (0 unexpected) in 924.059 (924.106) seconds
RUNTIME_SECONDS=$(grep -E "^[[:space:]]*Executed [0-9]+ tests, with " "$LOG_FILE" \
  | tail -1 \
  | sed -E 's/.*in ([0-9.]+).*/\1/' \
  || echo "0")

# Format runtime as Mm SSs (round seconds)
if [[ "$RUNTIME_SECONDS" =~ ^[0-9.]+$ ]]; then
  RUNTIME_INT=$(printf "%.0f" "$RUNTIME_SECONDS")
  MINUTES=$((RUNTIME_INT / 60))
  SECONDS=$((RUNTIME_INT % 60))
  if [[ $MINUTES -gt 0 ]]; then
    RUNTIME_STR="${MINUTES}m ${SECONDS}s"
  else
    RUNTIME_STR="${SECONDS}s"
  fi
else
  RUNTIME_STR="<unknown>"
fi

# ---- result emoji ----
EXIT_LINE=$(grep -E "^xcodebuild exit=" "$LOG_FILE" 2>/dev/null | tail -1)
if [[ -n "$EXIT_LINE" ]]; then
  EXIT_CODE=$(echo "$EXIT_LINE" | sed -E 's/^xcodebuild exit=([0-9]+).*/\1/')
else
  EXIT_CODE=""
fi

if [[ "$FAILED" -eq 0 ]] && [[ "$EXIT_CODE" == "0" || -z "$EXIT_CODE" ]]; then
  RESULT="✅ pass"
elif [[ "$FAILED" -gt 0 ]]; then
  RESULT="❌ fail"
else
  RESULT="⚠️ unknown"
fi

# ---- destination (parse from log if not provided) ----
if [[ -z "${DESTINATION:-}" ]]; then
  # xcodebuild echoes the chosen destination in lines like:
  #   { platform:iOS Simulator, ... OS:18.4, name:iPhone 16 }
  DEST_LINE=$(grep -E "^\s*\{ platform:iOS Simulator.*name:[A-Za-z]" "$LOG_FILE" 2>/dev/null | head -1 || true)
  if [[ -n "$DEST_LINE" ]]; then
    DEVICE_NAME=$(echo "$DEST_LINE" | sed -E 's/.*name:([^,}]+).*/\1/' | xargs)
    OS_VERSION=$(echo "$DEST_LINE" | sed -E 's/.*OS:([0-9.]+).*/\1/' | xargs)
    DESTINATION="${DEVICE_NAME} / iOS ${OS_VERSION}"
  else
    DESTINATION="<unknown>"
  fi
fi

# ---- plan name (parse from log if not provided) ----
if [[ -z "${PLAN_NAME:-}" ]]; then
  PLAN_LINE=$(grep -E "Test Plan: " "$LOG_FILE" 2>/dev/null | head -1 || true)
  if [[ -n "$PLAN_LINE" ]]; then
    PLAN_NAME=$(echo "$PLAN_LINE" | sed -E 's/.*Test Plan: ([A-Za-z0-9_-]+).*/\1/')
  else
    PLAN_NAME=""
  fi
fi

# ---- date (today, ISO) ----
RUN_DATE=$(date -u +%Y-%m-%d)

# ---- SDK version ----
SDK_VERSION="${SDK_VERSION:-<unknown>}"

# ---- emit row ----
printf "| %s | %s | %s | %s | %s | %s | %s | %s |\n" \
  "$RUN_DATE" \
  "$SDK_VERSION" \
  "$DESTINATION" \
  "$RESULT" \
  "$PASSED" \
  "$FAILED" \
  "$SKIPPED" \
  "$RUNTIME_STR"

# ---- helpful stderr summary so the user knows which table to paste into ----
{
  echo ""
  echo "Run date:    $RUN_DATE"
  echo "Plan:        ${PLAN_NAME:-<not parsed>}"
  echo "Destination: $DESTINATION"
  echo "Pass / Fail / Skip: $PASSED / $FAILED / $SKIPPED"
  echo "Runtime:     $RUNTIME_STR"
  echo "Result:      $RESULT"
  if [[ -n "${PLAN_NAME:-}" ]]; then
    echo ""
    echo "→ Test plan: ${PLAN_NAME}"
  fi
} >&2
