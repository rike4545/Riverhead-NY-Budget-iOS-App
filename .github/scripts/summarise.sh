#!/usr/bin/env bash
#
# Turns an xcodebuild log into a short GitHub step summary: the distinct
# error/failure lines first, then whatever test-count line the run produced.
# Deliberately tolerant — it runs with `if: always()`, including on runs that
# died before the log existed, and must never be the reason a job goes red.
set -uo pipefail

LOG="${1:?usage: summarise.sh <logfile> <heading>}"
HEADING="${2:-Run}"

echo "### $HEADING"
echo

if [ ! -f "$LOG" ]; then
  echo "_No log at \`$LOG\` — the run failed before xcodebuild produced output._"
  exit 0
fi

problems="$(grep -aE ': error:|^[[:space:]]*error:|XCTAssert.* failed|error: Test' "$LOG" \
  | sed 's/^[[:space:]]*//' | sort -u | head -40)"
if [ -n "$problems" ]; then
  echo '**Problems**'
  echo
  echo '```'
  printf '%s\n' "$problems"
  echo '```'
  echo
fi

counts="$(grep -aE 'Executed [0-9]+ test|Test run with [0-9]+ test|^\*\* (TEST|BUILD) (SUCCEEDED|FAILED)' "$LOG" \
  | sed 's/^[[:space:]]*//' | sort -u | head -20)"
if [ -n "$counts" ]; then
  echo '**Result**'
  echo
  echo '```'
  printf '%s\n' "$counts"
  echo '```'
else
  echo "_No test-count or build-status line in the log._"
fi
